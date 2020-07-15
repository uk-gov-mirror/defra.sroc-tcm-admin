require 'test_helper.rb'
require 'webmock/minitest'

class BillRunServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    # Disable network connections to enforce API mocking
    WebMock.disable_net_connect!

    @regime = regimes(:cfd)
    @region = 'W'
    @pre_sroc = true
    @service = BillRunService.new()
    @bill_run_url ||= URI.parse("#{ENV.fetch('CHARGING_MODULE_API')}/v1/#{@regime.slug}/billruns")
  end

  def teardown
    # Re-enable network connections
    WebMock.allow_net_connect!
  end

  def test_creates_new_record
    mock_id = '11111111-1111-1111-1111-111111111111'
    stub_request(:get, @bill_run_url).to_return(:body => single_bill_run_summary(mock_id, @region, @pre_sroc))

    # Confirm that a record doesn't yet exist in the bill run table
    br = BillRun.find_by(bill_run_id: mock_id)
    assert_nil br

    id = @service.get_bill_run_id(@regime.slug, @region, @pre_sroc)

    # Test that a record is now in the bill run table
    br = BillRun.find_by(bill_run_id: id)
    assert_equal br.bill_run_id, mock_id
    assert_equal br.regime, @regime.slug
    assert_equal br.region, @region
    assert_equal br.pre_sroc, @pre_sroc
  end

  def test_reads_existing_bill_run
    bill_run_id = '11111111-1111-1111-1111-111111111111'
    mock_id = '22222222-2222-2222-2222-222222222222'
    stub_request(:get, @bill_run_url).to_return(:body => single_bill_run_summary(mock_id, @region, @pre_sroc))

    # Create an entry in the bill run table
    br = BillRun.create(bill_run_id: bill_run_id, region: @region, regime: @regime.slug, pre_sroc: @pre_sroc)

    id = @service.get_bill_run_id(@regime.slug, @region, @pre_sroc)

    # Test that the returned id is the original entry and not one from the API
    assert_equal bill_run_id, id
  end

  def test_creates_new_bill_run
    mock_id = '11111111-1111-1111-1111-111111111111'
    stub_request(:get, @bill_run_url).to_return(:body => empty_bill_run_summary)
    stub_request(:post, @bill_run_url).to_return(:body => create_bill_run(mock_id))

    id = @service.get_bill_run_id(@regime.slug, @region, @pre_sroc)

    br = BillRun.find_by(bill_run_id: id)
    assert_equal br.bill_run_id, mock_id
    assert_equal br.regime, @regime.slug
    assert_equal br.region, @region
    assert_equal br.pre_sroc, @pre_sroc
  end

  def single_bill_run_summary(mock_id, region, pre_sroc)
    %Q(
      {
        "pagination": {
        "page": 1,
        "perPage": 50,
        "pageCount": 1,
        "recordCount": 1
      },
      "data": {
        "billRuns": [
          {
            "id": "#{mock_id}",
            "region": "#{region}",
            "billRunNumber": 10003,
            "fileId": null,
            "transactionFileReference": null,
            "transactionFileDate": null,
            "status": "initialised",
            "approvedForBilling": false,
            "preSroc": #{pre_sroc},
            "creditCount": 0,
            "creditValue": 0,
            "invoiceCount": 0,
            "invoiceValue": 0,
            "creditLineCount": 0,
            "creditLineValue": 0,
            "debitLineCount": 0,
            "debitLineValue": 0,
            "netTotal": 0
          }
        ]
      }
    }
    )
  end

  def empty_bill_run_summary
    %Q(
      {
        "pagination": {
            "page": 1,
            "perPage": 50,
            "pageCount": 0,
            "recordCount": 0
        },
        "data": {
            "billRuns": []
        }
    }
    )
  end

  def create_bill_run(bill_run_id)
    %Q(
      {
        "billRun": {
            "id": "#{bill_run_id}",
            "billRunNumber": 10001
        }
    }
    )

  end

end
