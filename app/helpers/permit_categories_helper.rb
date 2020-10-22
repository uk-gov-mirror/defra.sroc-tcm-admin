# frozen_string_literal: true

module PermitCategoriesHelper
  def pretty_financial_year(financial_year)
    "#{financial_year[0..1]}/#{financial_year[2..3]}" unless financial_year.blank?
  end
end
