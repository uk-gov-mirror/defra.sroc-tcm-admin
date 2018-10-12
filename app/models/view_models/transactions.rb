module ViewModels
  class Transactions
    include ActiveModel::AttributeAssignment

    attr_accessor :region, :financial_year, :search, :sort, :sort_direction,
      :page, :per_page, :transactions, :financial_years

  end
end
