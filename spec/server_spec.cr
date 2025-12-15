require "./spec_helper"

def with_default_destination(value)
  original = ENV["DEFAULT_DESTINATION"]?
  ENV["DEFAULT_DESTINATION"] = value
  yield
ensure
  if original
    ENV["DEFAULT_DESTINATION"] = original
  else
    ENV.delete("DEFAULT_DESTINATION")
  end
end

def without_default_destination
  original = ENV["DEFAULT_DESTINATION"]?
  ENV.delete("DEFAULT_DESTINATION")
  yield
ensure
  ENV["DEFAULT_DESTINATION"] = original if original
end

describe "UDL Server" do
  context "success" do
    it "redirects to the Target URI parameter if valid" do
      target_url = "https://fdo.cr/about"
      get "/?r=#{target_url}"

      response.status_code.should eq(302)
      response.headers["Location"].should eq(target_url)

      target_url = "http://fdo.cr/about"
      get "/?r=#{target_url}"

      response.status_code.should eq(302)
      response.headers["Location"].should eq(target_url)
    end

    it "redirects to DEFAULT_DESTINATION when root path has no r parameter and DEFAULT_DESTINATION is set" do
      with_default_destination("https://example.com") do
        get "/"

        response.status_code.should eq(302)
        response.headers["Location"].should eq("https://example.com")
      end
    end

    it "redirects to DEFAULT_DESTINATION + path when path has no r parameter and DEFAULT_DESTINATION is set" do
      with_default_destination("https://example.com") do
        get "/about"

        response.status_code.should eq(302)
        response.headers["Location"].should eq("https://example.com/about")
      end
    end

    it "populates apple-app-site-association file" do
      get "/.well-known/apple-app-site-association"

      result = "{\"applinks\":{\"apps\":[],\"details\":[{\"appID\":\"ABCDE12345.com.example.app\",\"paths\":[\"/*\"]},{\"appID\":\"ABCDE12345.com.example.app2\",\"paths\":[\"/*\"]}]},\"activitycontinuation\":{\"apps\":[\"ABCDE12345.com.example.app\",\"ABCDE12345.com.example.app2\"]}}"
      response.body.should eq(result)
      response.headers["Content-Type"].should eq("application/json")
    end
  end

  context "failure" do
    it "renders fallback page if target redirect not provided and DEFAULT_DESTINATION is not set" do
      without_default_destination do
        get "/"

        response.status_code.should eq(200)
        response.body.should contain("Something went wrong")
        response.body.should contain("Check out the <a href=\"https://github.com/fdocr/udl-server#Troubleshooting\">README</a> for more details")
      end
    end

    it "renders fallback page if requesting any other path and DEFAULT_DESTINATION is not set" do
      without_default_destination do
        get "/about-us"

        response.status_code.should eq(200)
        response.body.should contain("Something went wrong")
        response.body.should contain("Check out the <a href=\"https://github.com/fdocr/udl-server#Troubleshooting\">README</a> for more details")
      end
    end

    it "renders fallback page if r parameter is an invalid URL" do
      get "/?r=poorthing-ble$$-ur-<3"

      # When safelisting domains it will deny anything other than the provided
      # domains. When throttling it will fail and display error on response
      if ENV.fetch("SAFELIST", "").presence
        response.status_code.should eq(429)
      else
        response.status_code.should eq(200)
        response.body.should contain("Something went wrong")
        response.body.should contain("Check out the <a href=\"https://github.com/fdocr/udl-server#Troubleshooting\">README</a> for more details")
      end
    end
  end
end
