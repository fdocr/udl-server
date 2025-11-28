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
    redirect_param = env.params.query["r"]?

    # If no r parameter, redirect to DEFAULT_DESTINATION (only if set)
    unless redirect_param
      if default_destination = ENV["DEFAULT_DESTINATION"]?
        env.redirect default_destination
        next
      else
        raise "Missing redirect parameter"
      end
    end

    target_uri = URI.parse(redirect_param)

    # Check that it's a valid URL
    valid_uri = /https?/ =~ target_uri.scheme && target_uri.host
    raise "Invalid redirect URL" unless valid_uri

    # Redirect (bounce back) requested URL
    env.redirect target_uri.to_s
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
  # If DEFAULT_DESTINATION is set, redirect to it + path; otherwise show fallback.
  if default_target = ENV["DEFAULT_DESTINATION"]?
    path = env.request.path
    final_url = default_target.rstrip("/") + "/" + path.lstrip("/")
    env.redirect final_url
  else
    udl_error = "Invalid path `#{env.request.path}` - #{error_context}"
    render "src/views/fallback.ecr"
  end
end

error 404 do
  udl_error = "Resource Not Found - #{error_context}"
  render "src/views/fallback.ecr"
end

serve_static false
Kemal.config.port = ENV.fetch("PORT", "3000").to_i
Kemal.run
