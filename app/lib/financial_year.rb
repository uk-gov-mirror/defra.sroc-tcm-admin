module FinancialYear
  ValidYears = %w[ 1819 1920 2021 2122 2223 2324 2425 2526 2627 2728 ].freeze

  def valid_financial_year?(fy)
    ValidYears.include?(fy)
  end
end
