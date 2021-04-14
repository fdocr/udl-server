require 'sinatra'
if development?
  require "sinatra/reloader"
  require 'dotenv/load'
end
require 'uri'
require 'json'

get '/' do
  begin
    redirect URI(params[:r])
  rescue => error
    @error = error
    puts @error.inspect
    erb :fallback
  end
end

get '/*' do
  erb :fallback
end
