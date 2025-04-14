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

get "/s/:scheme/:url" do |env|
  begin
    fallback_url = URI.parse(env.params.url["url"])
    target_uri = URI.parse(env.params.url["url"])
    target_uri.scheme = env.params.url["scheme"]
    render "src/views/s.ecr"
  rescue udl_error
    render "src/views/fallback.ecr"
  end
end

get "/.well-known/apple-app-site-association" do |env|
  env.response.content_type = "application/json"

  if aasa_apps = ENV["AASA_APP_IDS"]?
    aasa_app_ids = aasa_apps.split(" ")
    {
      applinks: {
        apps:    [] of String,
        details: aasa_app_ids.map do |id|
          {appID: id, paths: ["/*"]}
        end,
      },
      activitycontinuation: {
        apps: aasa_app_ids,
      },
    }.to_json
  else
    {error: "AASA_APP_ID not configured"}.to_json
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
