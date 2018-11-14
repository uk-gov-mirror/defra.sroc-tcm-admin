module FinancialYear
  ValidYears = %w[ 1819 1920 2021 2122 2223 2324 2425 2526 2627 2728 ].freeze

  def valid_financial_year?(fy)
    ValidYears.include?(fy)
  end

  def current_financial_year
    d = Time.zone.now
    y = d.year - 2000
    if d.month > 3
      "#{y}#{y + 1}"
    else
      "#{y - 1}#{y}"
    end
  end
end
