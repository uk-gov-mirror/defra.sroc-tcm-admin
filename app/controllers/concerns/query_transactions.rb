# frozen_string_literal: true

module QueryTransactions
  extend ActiveSupport::Concern

  def build_view_model(all_regions: false)
    regions = Query::Regions.call(regime: @regime)
    region = params.fetch(:region, cookies.fetch(:region, ""))
    region = "" if region == "all"
    region = regions.first if region.blank? && !all_regions

    pg = params.fetch(:page, cookies.fetch(:page, 1))
    per_pg = params.fetch(:per_page, cookies.fetch(:per_page, 10))

    financial_years = Query::FinancialYears.call(regime: @regime)
    financial_year = params.fetch(:fy, cookies.fetch(:fy, ""))
    financial_year = "" unless financial_years.include? financial_year

    search = params.fetch(:search, cookies.fetch(:search, "")),
             sort = params.fetch(:sort, cookies.fetch(:sort, "customer_reference")),
             sort_direction = params.fetch(:sort_direction,
                                           cookies.fetch(:sort_direction, "asc"))

    vm = ViewModels::Transactions.new
    vm.assign_attributes(regime: @regime,
                         region: region,
                         available_regions: regions,
                         search: search,
                         sort: sort,
                         sort_direction: sort_direction,
                         page: pg,
                         per_page: per_pg,
                         financial_year: financial_year,
                         available_years: available_years)
    vm
  end

  def query_params
    {
      regime: @regime,
      region: @region,
      financial_year: @financial_year,
      search: params.fetch(:search, cookies.fetch(:search, "")),
      sort: params.fetch(:sort, cookies.fetch(:sort, "customer_reference")),
      sort_direction: params.fetch(:sort_direction,
                                   cookies.fetch(:sort_direction, "asc"))
    }
  end
end
