require 'sinatra/base'
require 'rack-auto-session-domain'
require_relative '../middleware/rest_pack_session'


class Debug < Sinatra::Base
  enable :sessions
  use Rack::AutoSessionDomain
  use RestPackSession

  get '/' do
    p "ENV: #{env}"
    p "==="

    p "SECRET: " + env['rack.session.options'][:secret]
    session[:count] ||= 0
    session[:count] = session[:count] + 1
    p session[:count]
    env.inspect
  end
end
