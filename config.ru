$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'api/sinatra'
require 'api/roda'

map '/sinatra' do
  run Api::SinatraApp
end

map '/roda' do
  run Api::RodaApp.freeze.app
end
