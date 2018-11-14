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
      q = @regime.transaction_details.historic

      assert_equal q.count, transactions.count

      transactions.each do |t|
        assert_includes q, t, "Where did #{t.reference_1} come from?"
      end
    end
  end
end
