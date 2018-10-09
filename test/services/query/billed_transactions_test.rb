require 'test_helper.rb'

module Query
  class BilledTransactionsTest < ActiveSupport::TestCase
    include GenerateHistory

    def setup
      @regime = regimes(:cfd)
      @user = users(:billing_admin)
      generate_historic_cfd
    end

    def test_returns_historic_transactions
      assert @regime.transaction_details.historic.count.positive?

      transactions = BilledTransactions.call(regime: @regime)
      assert_equal @regime.transaction_details.historic, transactions
    end
  end
end
