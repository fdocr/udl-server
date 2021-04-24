require "kemal"
require "uri"

error_context = "Use the root path instead `/?r=TARGET_URL_HERE`"

get "/" do |env|
  begin
    env.redirect URI.parse(env.params.query["r"]).to_s
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
Kemal.run
