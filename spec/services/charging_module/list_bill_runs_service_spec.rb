# frozen_string_literal: true

require "rails_helper"

module ChargingModule
  RSpec.describe ListBillRunsService do
    before(:each) do
      allow(ENV).to receive(:fetch).with("CHARGING_MODULE_API")
                                   .and_return("http://localhost:3002/")

      allow(AuthorisationService).to receive(:call).and_return(authorisation_service)

      stub_request(:get, "http://localhost:3002//test/billruns")
        .with(
          body: "null",
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => token,
            "Content-Type" => "application/json",
            "User-Agent" => "Ruby"
          }
        )
        .to_return(status: code, body: body, headers: {})
    end

    let(:token) { "abcde12345" }
    let(:authorisation_service) { double("AuthorisationService", token: token) }
    let(:regime) { "test" }
    let(:url) { "http://localhost:3002/v1/#{regime}" }

    context "when the request is valid" do
      let(:code) { 200 }
      let(:body) { File.read("spec/fixtures/charging_module/list_bill_runs_success.json") }

      it "returns a successful response" do
        result = described_class.call(regime: regime)

        expect(a_request(:get, url)).to have_been_made.at_most_once

        expect(result.success?).to be true
        expect(result.failed?).to be false
        expect(result.response).to eq(JSON.parse(body, symbolize_names: true))
      end
    end

    context "when the request fails" do
      let(:code) { 500 }
      let(:body) { nil }

      it "returns a failed response" do
        result = described_class.call(regime: regime)

        expect(a_request(:get, url)).to have_been_made.at_most_once

        expect(result.success?).to be false
        expect(result.failed?).to be true
        expect(result.response).to eq(nil)
      end
    end
  end
end
