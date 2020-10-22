# frozen_string_literal: true

require "test_helper"

module Query
  class TransactionsToBeBilledTest < ActiveSupport::TestCase
    def setup
      @regime = regimes(:cfd)
      @user = users(:billing_admin)
    end

    def test_returns_unbilled_transactions
      assert @regime.transaction_details.unbilled.count.positive?

      transactions = TransactionsToBeBilled.call(regime: @regime)
      q = @regime.transaction_details.unbilled

      assert_equal q.count, transactions.count

      transactions.each do |t|
        assert_includes q, t, "Where did #{t.reference_1} come from?"
      end
    end
  end
end
