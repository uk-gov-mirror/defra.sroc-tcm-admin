module QueryTransactions
  extend ActiveSupport::Concern

  def query_params
    fy = params.fetch(:fy, cookies.fetch(:fy, ''))
    fy = '' if fy == 'all'
    region = params.fetch(:region, cookies.fetch(:region, ''))
    region = '' if region == 'all'
    {
      regime: @regime,
      search: params.fetch(:search, cookies.fetch(:search, '')),
      region: region,
      sort: params.fetch(:sort, cookies.fetch(:sort, 'customer_reference')),
      sort_direction: params.fetch(:sort_direction,
                                   cookies.fetch(:sort_direction, 'asc')),
      financial_year: fy
    }
  end
end
