require "kemal"
require "defense"
require "uri"

error_context = "Use the root path instead `/?r=TARGET_URL_HERE`"

# # Defense config
# Defense.store = Defense::MemoryStore.new
# # Defense.store = Defense::RedisStore.new
# limit = ENV.fetch("THROTTLE_LIMIT", "10").to_i
# period = ENV.fetch("THROTTLE_PERIOD", "20").to_i

# if ENV.has_key?("SAFELIST_REGEX")
#   safelist_regex = Regex.new(ENV["SAFELIST_REGEX"], Regex::CompileOptions::IGNORE_CASE)
#   Defense.safelist("blocklist redirects") do |request|
#     !(request.query_params["r"]? =~ safelist_regex).nil?
#   end

#   # Override limit to block off other domains
#   limit = 0
# end

# Defense.throttle("req/ip", limit: limit, period: period) do |request|
#   # To throttle on localhost -> request.remote_address.to_s.split(":").first
#   request.remote_address.to_s
#   request.remote_address.to_s.split(":").first
# end

# add_handler Defense::Handler.new

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
