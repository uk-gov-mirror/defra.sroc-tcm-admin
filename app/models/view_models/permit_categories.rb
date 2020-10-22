# frozen_string_literal: true

module ViewModels
  class PermitCategories
    include ActiveModel::AttributeAssignment

    attr_accessor :financial_year, :search, :sort, :sort_direction,
                  :page, :per_page, :permit_categories, :financial_years

  end
end
