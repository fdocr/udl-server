require "./spec_helper"

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
  end

  context "failure" do
    it "renders fallback page if target redirect not provided" do
      get "/"

      response.status_code.should eq(200)
      response.body.should contain("Something went wrong")
      response.body.should contain("Check out the <a href=\"https://github.com/fdocr/udl-server#Troubleshooting\">README</a> for more details")
    end

    it "renders fallback page if requesting any other path" do
      get "/about-us"

      response.status_code.should eq(200)
      response.body.should contain("Something went wrong")
      response.body.should contain("Check out the <a href=\"https://github.com/fdocr/udl-server#Troubleshooting\">README</a> for more details")
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
