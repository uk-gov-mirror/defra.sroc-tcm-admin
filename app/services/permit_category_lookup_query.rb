# frozen_string_literal: true

class PermitCategoryLookupQuery < QueryObject
  def initialize(opts = {})
    @regime = opts.fetch(:regime)
    @financial_year = opts.fetch(:financial_year)
    @query = opts.fetch(:query, '')
  end
    
  def call
    q = @regime.permit_categories.by_financial_year(@financial_year).active
    q = q.where(PermitCategory.arel_table[:code].matches("%#{@query}%")) unless @query.blank?
    q.order("string_to_array(code, '.')::int[]")
  end
end
