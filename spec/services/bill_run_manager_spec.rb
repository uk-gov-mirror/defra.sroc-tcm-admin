# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BillRunManager do
  before(:each) do
    allow(ENV).to receive(:fetch).with('CHARGING_MODULE_API')
                                 .and_return('http://localhost:3002/')

    allow(ChargingModule::AuthorisationService).to receive(:call).and_return(authorisation_service)

    stub_request(:get, 'http://localhost:3002//test/billruns')
      .with(
        body: 'null',
        query: hash_including({}), # This mocks get request regardless of query string
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => token,
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: code, body: get_body, headers: {})

    stub_request(:post, 'http://localhost:3002//test/billruns')
      .with(
        body: {
          'region' => region
        },
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => token,
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: code, body: post_body, headers: {})
  end

  let(:token) { 'abcde12345' }
  let(:authorisation_service) { double('AuthorisationService', token: token) }
  let(:regime) { 'test' }
  let(:region) { 'S' }
  let(:pre_sroc) { true }
  let(:url) { "http://localhost:3002//#{regime}/billruns" }
  let(:bill_run_id) { '11111111-1111-1111-1111-111111111111' }
  let(:mock_id) { '22222222-2222-2222-2222-222222222222' }

  context 'when a bill run exists in the bill run manager table' do
    let(:code) { 200 }
    let(:get_body) { DynamicFixtures::BillRun.single_bill_run_summary(mock_id, region, pre_sroc) }
    let(:post_body) { nil }

    it 'returns the id from the table' do
      # Create an entry in the bill run table
      BillRun.create(bill_run_id: bill_run_id, region: region, regime: regime, pre_sroc: pre_sroc)

      bill_run_manager = described_class.call(regime: regime, region: region, pre_sroc: pre_sroc)
      expect(bill_run_manager.success?).to eq(true)

      # Test that the API hasn't been hit
      expect(a_request(:get, url)).not_to have_been_made
      expect(a_request(:post, url)).not_to have_been_made
      # Test that the returned id is the original entry and not one from the API
      expect(bill_run_manager.bill_run_id).to eq(bill_run_id)
    end
  end

  context 'when a bill run doesn\'t exist in the bill run manager table' do
    context 'and a bill run exists in the API' do
      let(:code) { 200 }
      let(:get_body) { DynamicFixtures::BillRun.single_bill_run_summary(mock_id, region, pre_sroc) }
      let(:post_body) { nil }

      it 'creates a new record in the table' do
        # Confirm that a record doesn't yet exist in the bill run table
        bill_run = BillRun.find_by(bill_run_id: mock_id)
        expect(bill_run).to be_nil

        bill_run_manager = described_class.call(regime: regime, region: region, pre_sroc: pre_sroc)
        expect(bill_run_manager.success?).to eq(true)

        # Test that only the GET endpoint has been hit
        expect(a_request(:post, url)).not_to have_been_made
        expect(a_request(:get, url)
          .with(query: hash_including({})))
          .to have_been_made.once

        # Test that a record is now in the bill run table
        bill_run = BillRun.find_by(bill_run_id: bill_run_manager.bill_run_id)
        expect(bill_run.bill_run_id).to eq(mock_id)
        expect(bill_run.regime).to eq(regime)
        expect(bill_run.region).to eq(region)
        expect(bill_run.pre_sroc).to eq(pre_sroc)
      end
    end

    context 'and a bill run doesn\'t exist in the API' do
      let(:code) { 200 }
      let(:get_body) { DynamicFixtures::BillRun.empty_bill_run_summary }
      let(:post_body) { DynamicFixtures::BillRun.create_bill_run(mock_id) }

      it 'creates a new bill run' do
        bill_run_manager = described_class.call(regime: regime, region: region, pre_sroc: pre_sroc)
        expect(bill_run_manager.success?).to eq(true)

        # Test that both endpoints have been hit
        expect(a_request(:post, url)).to have_been_made.once
        expect(a_request(:get, url)
          .with(query: hash_including({})))
          .to have_been_made.once

        bill_run = BillRun.find_by(bill_run_id: bill_run_manager.bill_run_id)
        expect(bill_run.bill_run_id).to eq(mock_id)
        expect(bill_run.regime).to eq(regime)
        expect(bill_run.region).to eq(region)
        expect(bill_run.pre_sroc).to eq(pre_sroc)
      end
    end
  end

  context 'when the request fails' do
    let(:code) { 500 }
    let(:get_body) { nil }
    let(:post_body) { nil }

    it 'returns a failed response' do
      result = described_class.call(regime: regime, region: region, pre_sroc: pre_sroc)

      expect(a_request(:get, url)).to have_been_made.at_most_once
      expect(a_request(:post, url)).to have_been_made.at_most_once

      expect(result.success?).to be false
      expect(result.failed?).to be true
      expect(result.bill_run_id).to eq(nil)
    end
  end
end
