require 'test_helper.rb'

module Query
  class PreSrocTransactionsTest < ActiveSupport::TestCase
    def setup
      @regime = regimes(:cfd)
      @regime.transaction_details.update_all(status: 'retrospective')
    end

    def test_returns_pre_sroc_transactions
      assert @regime.transaction_details.retrospective.count.positive?

      transactions = PreSrocTransactions.call(regime: @regime)
      assert_equal @regime.transaction_details.retrospective, transactions
    end
  end
end

