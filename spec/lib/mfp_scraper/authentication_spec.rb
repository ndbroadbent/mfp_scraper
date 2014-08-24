require 'spec_helper'

describe MFPScraper::Authentication, :vcr do
  it "should not allow authentication for invalid credentials" do
    mfp = MFPScraper.new(username: 'invalid_username', password: 'invalid_password')
    result = mfp.authenticate!

    expect(result).to eq false
    expect(mfp.authenticated?).to eq false
  end

  it "should allow authentication for valid credentials" do
    mfp = client_with_valid_credentials
    result = mfp.authenticate!

    expect(result).to eq true
    expect(mfp.authenticated?).to eq true
  end

  it "should allow authentication for valid credentials" do
    mfp = client_with_valid_credentials
    mfp.authenticate!

    username = mfp.fetch_username
    expect(username).to eq 'nathanf77'
  end
end
