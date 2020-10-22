# frozen_string_literal: true

require "rails_helper"

module ChargingModule
  RSpec.describe AuthorisationService do
    before(:each) do
      allow(ENV).to receive(:fetch).with("COGNITO_HOST")
                                   .and_return("http://example.com")
      allow(ENV).to receive(:fetch).with("COGNITO_USERNAME")
                                   .and_return("auser")
      allow(ENV).to receive(:fetch).with("COGNITO_PASSWORD")
                                   .and_return("password12345")

      allow(OAuth2::Client).to receive(:new)
        .with("auser", "password12345", site: "http://example.com", token_url: "/oauth2/token")
        .and_return(oauth2_client)
    end

    let(:oauth2_client) { double("OAuth2::Client", client_credentials: client_credentials) }
    let(:client_credentials) { double("OAuth2::Strategy::ClientCredentials", get_token: access_token) }
    let(:access_token) { double("OAuth2::AccessToken", token: token) }
    let(:token) { "abcde12345" }

    context "when everything is valid" do
      it "returns a token" do
        auth_service = described_class.call

        expect(auth_service.token).to eq(token)
      end

      it "is successful" do
        auth_service = described_class.call

        expect(auth_service.success?).to be true
      end
    end

    context "when authorisation fails" do
      context "because the credentials are wrong" do
        before do
          stub_const("OAuth2::Error", StandardError)
          allow(client_credentials).to receive(:get_token).and_raise(OAuth2::Error)
        end

        it "raises an error" do
          expect { described_class.call }.to raise_error(OAuth2::Error)
        end
      end
    end
  end
end
