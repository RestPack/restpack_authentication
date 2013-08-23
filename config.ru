require 'restpack_core_service'
require 'restpack_user_service'
require './apps/home'
require './apps/oauth'

map '/' do
  run Home
end

map '/oauth' do
  run OAuth
end
