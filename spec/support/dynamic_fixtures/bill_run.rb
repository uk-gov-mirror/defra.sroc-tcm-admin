# frozen_string_literal: true

module DynamicFixtures
  class BillRun
    def self.single_bill_run_summary(mock_id, region, pre_sroc)
      %(
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

    def self.empty_bill_run_summary
      %(
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

    def self.create_bill_run(bill_run_id)
      %(
        {
          "billRun": {
              "id": "#{bill_run_id}",
              "billRunNumber": 10001
          }
      }
      )
    end
  end
end
