require 'sinatra'
if !production?
  require 'sinatra/reloader'
  require 'dotenv/load'
  require 'byebug'
end

require 'uri'
require 'json'
require 'redis-activesupport'
require 'rack/attack'

Rack::Attack.cache.store = ActiveSupport::Cache.lookup_store :redis_store

http_redirect_regexp = /^https?:\/.+/
scheme_redirect_regexp = /^\S+:\/.+/

if ENV['UDL_THROTTLE_LIMIT'].present? && ENV['UDL_THROTTLE_PERIOD'].present?
  limit = ENV['UDL_THROTTLE_LIMIT'].to_i
  period = ENV['UDL_THROTTLE_PERIOD'].to_i
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
    requested_url = params[:r]
    if http_redirect_regexp.match(requested_url)
      redirect URI(requested_url)
    elsif scheme_redirect_regexp.match(requested_url)
      redirect requested_url
    else
      raise 'Requested URI is invalid'
    end
  rescue => error
    @error = error
    logger.info @error.inspect
    erb :fallback
  end
end

get '/.well-known/apple-app-site-association' do
  content_type :json

  aasa_app_id = ENV['AASA_APP_ID'].to_s
  if aasa_app_id.present?
    {
      "applinks": {
        "apps": [],
        "details":[
          {
            "appID": aasa_app_id,
            "paths": ["/*"]
          }
        ]
      },
      "activitycontinuation": {
        "apps": [aasa_app_id]
      }
    }.to_json
  else
    { error: 'AASA_APP_ID not configured' }.to_json
  end
end

get '/*' do
  begin
    requested_url = params['splat'].first
    if http_redirect_regexp.match(requested_url)
      target_url = URI(requested_url.gsub(':/', '://'))
      raise 'Invalid redirect URL' if target_url&.host.nil?
      redirect target_url
    elsif scheme_redirect_regexp.match(requested_url)
      redirect requested_url.gsub(':/', ':///')
    else
      raise 'Target redirect location must have a scheme'
    end
  rescue => error
    @error = error
    logger.info @error.inspect
    erb :fallback
  end
end
