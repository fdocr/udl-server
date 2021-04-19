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
    it "redirects to the r parameter if valid" do
      target_url = "https://dev.to/fdoxyz"
      get "/?r=#{target_url}"
      expect(last_response).to be_redirect
      expect(last_response.location).to eq(target_url)
    end
  end

  context "failure" do
    after(:each) do
      expect(last_response).to be_ok
      expect(last_response.body).to include('Something went wrong')
      expect(last_response.body).to include('Check out the <a href="https://github.com/fdoxyz/udl-server#Troubleshooting">README</a> for more details')
    end

    it "renders fallback page if r parameter isn't available" do
      get '/'
    end

    it "renders fallback page if requesting any other path" do
      get '/about-us'
    end

    it "renders fallback page if r parameter is an invalid URL" do
      get '/?r=poorthing-ble$$ur<3'
    end
  end
end
