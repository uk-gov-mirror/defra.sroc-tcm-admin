# frozen_string_literal: true

require "test_helper"

module Query
  class TransctionFileYearsTest < ActiveSupport::TestCase

    def setup
      @regime = regimes(:cfd)
      @file = transaction_files(:cfd_sroc_file)
      @regime.transaction_details.update_all(status: "billed",
                                             transaction_file_id: @file.id)
    end

    def test_returns_the_financial_years_for_transactions_in_file
      assert @file.transaction_details.count.positive?

      years = TransactionFileYears.call(transaction_file: @file)
      expected = @file.transaction_details.distinct.pluck(:tcm_financial_year).sort
      assert_equal expected, years
    end
  end
end
