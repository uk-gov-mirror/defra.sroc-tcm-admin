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
      assert_equal @regime.transaction_details.historic_excluded, transactions
    end
  end
end
