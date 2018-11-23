require 'test_helper.rb'

module Query
  class BilledTransactionsTest < ActiveSupport::TestCase
    include GenerateHistory

    def setup
      @regime = regimes(:cfd)
      @user = users(:billing_admin)
      @history = generate_historic_cfd
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

    def test_it_can_search_extra_attributes
      @history.each do |t|
        t.update_attributes(tcm_transaction_reference: "x1y2z3",
                            generated_filename: "wig77wam")
      end
      # search category, tcm_transaction_reference, generated_filename
      [ '3.4', 'y2z', 'wig77' ].each do |v|
        transactions = BilledTransactions.call(regime: @regime,
                                               search: v)
        assert transactions.count.positive?, "Failed on [#{v}]"
      end
    end
  end
end
