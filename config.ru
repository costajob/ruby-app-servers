$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'api/roda'

run Api::RodaApp.freeze.app
