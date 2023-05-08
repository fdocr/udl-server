ENV['APP_ENV'] = 'test'

require './server'  # <-- your sinatra app
require 'rspec'
require 'rack/test'

RSpec.describe 'UDL Server' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  context "success" do
    let(:http_target_url) { "https://dev.to/fdocr" }
    let(:custom_scheme_target_url) { "ms-mobile-apps:///providers/Microsoft.PowerApps/apps/123?tenantId=456" }

    context "using r query parameter" do
      it "redirects if URL is valid" do
        get "/?r=#{http_target_url}"
        expect(last_response).to be_redirect
        expect(last_response.location).to eq(http_target_url)
      end

      it "redirects to MS Power Apps schemes" do 
        get "/?r=#{custom_scheme_target_url}"
        expect(last_response).to be_redirect
      end
    end

    context "using REST first level param" do
      it "redirects if URL is valid" do
        get "/#{http_target_url}"
        expect(last_response).to be_redirect
        expect(last_response.location).to eq(http_target_url)
      end

      it "redirects to MS Power Apps schemes" do
        get "/#{custom_scheme_target_url}"
        expect(last_response).to be_redirect
      end
    end
  end

  context "failure" do
    after(:each) do
      expect(last_response).to be_ok
      expect(last_response.body).to include('Something went wrong')
      expect(last_response.body).to include('Check out the <a href="https://github.com/fdocr/udl-server#Troubleshooting">README</a> for more details')
    end

    it "renders fallback page if r parameter isn't available" do
      get '/'
    end

    it "renders fallback page if requesting anything other than URL redirect" do
      get '/about-us'
    end

    it "renders fallback page if r parameter is an invalid URL" do
      get '/?r=poorthing-ble$$ur<3'
    end
  end

  context "AASA" do
    it "responds with AASA when AASA_APP_ID is configured" do
      allow(ENV).to receive(:[]).with('AASA_APP_ID').and_return("R9SWHSQNV8.com.forem.app")
      get '/.well-known/apple-app-site-association'
      expect(last_response).to be_ok
      expect(last_response.body).to eq("{\"applinks\":{\"apps\":[],\"details\":[{\"appID\":\"R9SWHSQNV8.com.forem.app\",\"paths\":[\"/*\"]}]},\"activitycontinuation\":{\"apps\":[\"R9SWHSQNV8.com.forem.app\"]}}")
    end

    it "responds with error when AASA_APP_ID isn't configured" do
      allow(ENV).to receive(:[]).with('AASA_APP_ID').and_return("")
      get '/.well-known/apple-app-site-association'
      expect(last_response).to be_ok
      expect(last_response.body).to eq("{\"error\":\"AASA_APP_ID not configured\"}")
    end
  end
end
