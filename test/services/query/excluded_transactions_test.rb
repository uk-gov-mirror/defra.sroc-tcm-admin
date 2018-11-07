require 'test_helper.rb'

module Query
  class ExcludedTransactionsTest < ActiveSupport::TestCase
    def setup
      @regime = regimes(:cfd)
      @user = users(:billing_admin)
      @regime.transaction_details.update_all(status: 'excluded')
    end

    def test_returns_permanently_excluded_transactions
      assert @regime.transaction_details.historic_excluded.count.positive?

      transactions = ExcludedTransactions.call(regime: @regime)
      q =  @regime.transaction_details.historic_excluded
      assert_equal q.count, transactions.count

      transactions.each do |t|
        assert_includes q, t, "Where did #{t.reference_1} come from?"
      end
    end
  end
end
