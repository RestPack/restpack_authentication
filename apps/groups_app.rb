require 'sinatra'
require 'restpack_web'

class GroupsApp < Sinatra::Base
  set :sessions, true
  include RestPack::Web::Sinatra::App

  get '/rsvp' do
    if @restpack.authenticated?
      p "Accept group invitation"

      response = Commands::Groups::Invitation::Rsvp.run({
        application_id: @restpack.application_id,
        user_id: @restpack.user_id,
        access_key: params[:access_key],
        accept: params[:accept] || true
      })

      if response.success?
        p "RESPONSE: #{response.inspect}"
        return 'redirecting...'
      else
        p response.inspect
        p "TODO: GJ: show error message"
      end
    else
      return "TODO: show login buttons..."
    end
  end
end
