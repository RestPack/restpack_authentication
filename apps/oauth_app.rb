require 'sinatra'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-google-oauth2'
require 'omniauth-github'

require 'restpack_web'

class OAuthApp < Sinatra::Base
  set :sessions, true
  use RestPack::Web::Rack::Domain
  use RestPack::Web::Rack::Session

  get '/' do
     "Welcome to the authentication service for #{restpack[:domain][:identifier]}"
  end

  %w(get post).each do |method|
    send(method, "/auth/:provider/callback") do
      response = RestPack::User::Service::Commands::User::OmniAuthenticate.run({
        application_id: restpack[:application_id],
        omniauth_response: env['omniauth.auth']
      })
      raise unless response.success?

      user = response.result[:users].first
      restpack_session[:user_id] = user[:id]
      restpack_session[:account_id] = get_account_id(user)

      redirect request.env['omniauth.origin'] || '/'
    end
   end

  get '/auth/logout' do
    restpack_session.clear
    redirect params[:next] || '/'
  end

  private

  def get_account_id(user)
    #NOTE: GJ: this needs a big refactor once we've come up with a nice dsl for the services
    response = RestPack::Group::Service::Commands::Membership::List.run({
      application_id: restpack[:application_id],
      user_id: user[:id],
      is_account_group: true
    })
    raise unless response.success?

    if response.result[:memberships].any?
      #TODO: GJ: return the default membership.account_id
      return response.result[:memberships][0][:account_id]
    else #create an account and group for this user
      response = RestPack::Account::Service::Commands::Account::Create.run({
        accounts: [{
          application_id: restpack[:application_id],
          created_by: user[:id],
          name: user[:name]
        }]
      })
      raise unless response.success?

      account_id = response.result[:accounts][0][:id]

      response = RestPack::Group::Service::Commands::Group::Create.run({
        groups: [{
          application_id: user[:application_id],
          created_by: user[:id],
          name: user[:name],
          account_id: account_id,
          invitation_required: true #TODO: GJ: perhaps this should default to true? or maybe renamed to public?
        }]
      })
      raise unless response.success?

      return account_id
    end
  end

  def restpack
    env['restpack']
  end

  def restpack_session
    env['restpack.session']
  end

  OmniAuthSetup = lambda do |env|
    strategy = env['omniauth.strategy'].name.to_sym

    domain = env['restpack'][:domain]
    oauth_configuration = domain[:oauth_providers]

    if oauth_configuration.nil? or oauth_configuration.empty?
      raise "[#{domain[:identifier]}] has no OAUTH configuration"
    end

    strategy_config = oauth_configuration[strategy.to_s]
    if strategy_config.nil? or oauth_configuration.empty?
      raise "[#{domain[:identifier]}] has no OAUTH [#{strategy}] configuration"
    end

    env['omniauth.strategy'].options[:consumer_key] = strategy_config['key']
    env['omniauth.strategy'].options[:consumer_secret] = strategy_config['secret']

    env['omniauth.strategy'].options[:client_id] = strategy_config['key']
    env['omniauth.strategy'].options[:client_secret] = strategy_config['secret']

    if strategy == :google_oauth2
      env['omniauth.strategy'].options[:authorize_params] = {access_type: 'online', approval_prompt: ''}
    end
  end

  use OmniAuth::Builder do
    provider :twitter, :setup => OmniAuthSetup
    provider :google_oauth2, :setup => OmniAuthSetup
    provider :github, :setup => OmniAuthSetup
  end
end
