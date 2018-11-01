module ViewModels
  class Exclusions < Transactions
    def fetch_transactions
      Query::ExcludedTransactions.call(regime: regime,
                                       region: region,
                                       sort: sort,
                                       sort_direction: sort_direction,
                                       financial_year: financial_year,
                                       search: search)
    end
    
    def region_options
      all_region_options
    end
  end
end
