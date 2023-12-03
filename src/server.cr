require "uri"
require "kemal"
require "dotenv"

Dotenv.load if (Kemal.config.env == "development") && File.exists?(".env")
Dotenv.load(path: ".env.test") if Kemal.config.env == "test"

require "../config/**"

add_handler Defense::Handler.new unless ENV["DISABLE_DEFENSE"]?.presence

error_context = "Use the root path instead, i.e. `/?r=TARGET_URL_HERE`"

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
Kemal.config.port = ENV.fetch("PORT", "3000").to_i
Kemal.run
