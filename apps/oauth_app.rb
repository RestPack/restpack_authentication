require 'sinatra'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-google-oauth2'
require 'rack-auto-session-domain'

class OAuthApp < Sinatra::Base
  enable :sessions
  use Rack::AutoSessionDomain
  use RestPackSession

  get '/' do
    "Welcome to the authentication service for #{env['restpack.domain'][:identifier]}"
  end

  %w(get post).each do |method|
    send(method, "/auth/:provider/callback") do
      response = RestPack::User::Service::Commands::User::OmniAuthenticate.run({
        application_id: env['restpack.domain'][:application_id],
        omniauth_response: env['omniauth.auth']
      })

      if response.success?
        user = response.result[:users].first
        session[:user_id] = user['id']
        redirect params[:next] || '/'
      else
        "ERROR"
      end
    end
   end

  get '/auth/logout' do
    session[:user_id] = nil
    redirect params[:next] || '/'
  end

  OmniAuthSetup = lambda do |env|
    strategy = env['omniauth.strategy'].name.to_sym

    domain = env['restpack.domain']
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

    if strategy == :google_oauth2
      env['omniauth.strategy'].options[:client_id] = strategy_config['key']
      env['omniauth.strategy'].options[:client_secret] = strategy_config[secret]
      env['omniauth.strategy'].options[:authorize_params] = {access_type: 'online', approval_prompt: ''}
    end
  end

  use OmniAuth::Builder do
    provider :twitter, :setup => OmniAuthSetup
    provider :google_oauth2, :setup => OmniAuthSetup
  end
end
