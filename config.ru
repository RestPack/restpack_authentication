require 'restpack_core_service'
require 'restpack_user_service'
require './apps/oauth_app'

config = YAML.load(IO.read('config/database.yml'))
environment = ENV['RAILS_ENV'] || ENV['DB'] || 'development'
ActiveRecord::Base.establish_connection config[environment]

map '/' do
  run OAuthApp
end
