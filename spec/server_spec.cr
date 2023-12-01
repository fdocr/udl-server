require "./spec_helper"

describe "UDL Server" do
  context "success" do
    it "redirects to the r parameter if valid" do
      target_url = "https://dev.to/fdocr"
      get "/?r=#{target_url}"

      response.headers["Location"].should eq(target_url)
      response.status_code.should eq(302)
    end
  end

  context "failure" do
    it "renders fallback page if r parameter isn't available" do
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
      get "/?r=poorthing-ble$$ur<3"

      response.status_code.should eq(200)
      response.body.should contain("Something went wrong")
      response.body.should contain("Check out the <a href=\"https://github.com/fdocr/udl-server#Troubleshooting\">README</a> for more details")
    end
  end
end
