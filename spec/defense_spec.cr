require "./spec_helper"

describe "Defense" do
  context "throttle" do
    it "throttles (with defaults)" do
      target_url = "https://example.com/dolan"

      5.times do
        get "/?r=#{target_url}"

        response.status_code.should eq(302)
        response.headers["Location"].should eq(target_url)
      end

      5.times do
        get "/?r=#{target_url}"
        response.status_code.should eq(429)
      end
    end
  end unless ENV.fetch("SAFELIST", "").presence

  context "safelist" do
    it "allows domain to bypass throttling" do
      target_url = "https://fdo.cr/about"

      50.times do
        get "/?r=#{target_url}"

        response.status_code.should eq(302)
        response.headers["Location"].should eq(target_url)
      end
    end

    it "blocks all domains not safelisted" do
      3.times do
        get "/?r=https://example.com/dolan"
        response.status_code.should eq(429)
      end
    end
  end if ENV.fetch("SAFELIST", "").presence
end
