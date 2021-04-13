require 'sinatra'
require "sinatra/reloader" if development?
require 'uri'

get '/' do
  redirect URI(params[:r])
end

post '/' do
  redirect URI(params[:r])
end
