# frozen_string_literal: true

require "test_helper"

module Query
  class PreSrocTransactionsTest < ActiveSupport::TestCase
    def setup
      @regime = regimes(:cfd)
      @regime.transaction_details.update_all(status: "retrospective")
    end

    def test_returns_pre_sroc_transactions
      assert @regime.transaction_details.retrospective.count.positive?

      transactions = PreSrocTransactions.call(regime: @regime)
      q = @regime.transaction_details.retrospective

      assert_equal q.count, transactions.count

      transactions.each do |t|
        assert_includes q, t, "Where did #{t.reference_1} come from?"
      end
    end
  end
end
