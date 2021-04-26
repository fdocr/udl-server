require "kemal"
require "defense"
require "uri"

error_context = "Use the root path instead `/?r=TARGET_URL_HERE`"

if ENV.has_key?("UDL_THROTTLE_LIMIT") && ENV.has_key?("UDL_THROTTLE_PERIOD")
  limit = ENV["UDL_THROTTLE_LIMIT"].to_i
  period = ENV["UDL_THROTTLE_PERIOD"].to_i
  Defense.throttle("req/ip", limit: limit, period: period) do |request|
    # To throttle on localhost -> request.remote_address.to_s.split(":").first
    request.remote_address.to_s
  end
end

if ENV.has_key?("UDL_SAFELIST_REGEXP")
  safelist_regexp = Regex.new(ENV["UDL_SAFELIST_REGEXP"])
  Defense.safelist("blocklist redirects") do |request|
    !(request.query_params["r"] =~ safelist_regexp).nil?
  end
end

if ENV.has_key?("UDL_BLOCKLIST_REGEXP")
  blocklist_regexp = Regex.new(ENV["UDL_BLOCKLIST_REGEXP"])
  Defense.blocklist("safelist redirects") do |request|
    !(request.query_params["r"] =~ blocklist_regexp).nil?
  end
end

add_handler Defense::Handler.new

get "/" do |env|
  begin
    target_uri = URI.parse(env.params.query["r"])

    # Check that it's a valid URL
    valid_uri = /https?/ =~ target_uri.scheme && target_uri.host
    raise "Invalid redirect URL" unless valid_uri

    # Redirect (bounce back) requested URL
    env.redirect target_uri.to_s
  rescue udl_error
    render "src/views/fallback.ecr"
  end
end

get "/*" do |env|
  udl_error = "Invalid path `#{env.request.path}` - #{error_context}"
  render "src/views/fallback.ecr"
end

error 404 do
  udl_error = "Resource Not Found - #{error_context}"
  render "src/views/fallback.ecr"
end

serve_static false
Kemal.config.port = (ENV["PORT"]? || "3000").to_i
Kemal.run
