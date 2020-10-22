# frozen_string_literal: true

module ViewModels
  class Historic < Transactions
    def initialize(params = {})
      super(params)
      @permit_all_regions = true
    end

    def fetch_transactions
      Query::BilledTransactions.call(regime: regime,
                                     region: region,
                                     sort: sort,
                                     sort_direction: sort_direction,
                                     financial_year: financial_year,
                                     search: search)
    end

    def csv_transactions(limit = 15_000)
      @csv_transactions ||= presenter.wrap(transactions.limit(limit), user)
    end

    def region_options
      all_region_options
    end
  end
end
