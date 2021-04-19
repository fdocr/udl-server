require 'sinatra'
if !production?
  require 'sinatra/reloader'
  require 'dotenv/load'
  require 'byebug'
end

require 'uri'
require 'redis-activesupport'
require 'rack/attack'

if ENV['REDIS_URL'].present?
  Rack::Attack.cache.store = ActiveSupport::Cache.lookup_store :redis_store

  limit = (ENV['UDL_THROTTLE_LIMIT'] || 3).to_i
  period = (ENV['UDL_THROTTLE_PERIOD'] || 10).to_i
  Rack::Attack.throttle('requests/ip', limit: limit, period: period) do |request|
    request.ip
  end
end

if ENV['UDL_SAFELIST_REGEXP'].present?
  safelist_regexp = Regexp.new(ENV['UDL_SAFELIST_REGEXP'])
  Rack::Attack.safelist("allow safelist") do |request|
    # Requests will be safelisted if the 'r' param matches the regexp
    request.params["r"] =~ safelist_regexp
  end
end

if ENV['UDL_BLOCKLIST_REGEXP'].present?
  blocklist_regexp = Regexp.new(ENV['UDL_BLOCKLIST_REGEXP'])
  Rack::Attack.blocklist("deny blocklist") do |request|
    # Requests will be blocklisted if the 'r' param matches the regexp
    request.params["r"] =~ blocklist_regexp
  end
end

get '/' do
  begin
    redirect URI(params[:r])
  rescue => error
    @error = error
    logger.info @error.inspect
    erb :fallback
  end
end

get '/*' do
  erb :fallback
end
