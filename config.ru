require "rack/attack"
use Rack::Attack

require "./server"
run Sinatra::Application
