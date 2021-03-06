require 'restpack_core_service'
require 'restpack_user_service'
require 'restpack_group_service'
require 'restpack_account_service'
require './apps/oauth_app'
require './apps/groups_app'

config = YAML.load(IO.read('config/database.yml'))
environment = ENV['RAILS_ENV'] || ENV['DB'] || 'development'
ActiveRecord::Base.establish_connection config[environment]

map '/groups' do
  run GroupsApp
end

map '/' do
  run OAuthApp
end
