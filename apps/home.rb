require 'sinatra/base'

class Home < Sinatra::Base
  get '/' do
    'Welcome to the RestPack authentication service'
  end
end
