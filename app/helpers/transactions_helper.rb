module TransactionsHelper
  def present_transaction(transaction)
    name = "#{transaction.regime.slug}_transaction_detail_presenter".camelize
    presenter = str_to_class(name) || TransactionDetailsPresenter
    presenter.new(transaction)
  end

  def search_placeholder(regime)
    if regime.water_quality?
      "Search for Customer or Consent references matching ..."
    else
      "Search for Customer or Permit references matching ..."
    end
  end

  def str_to_class(name)
    begin
      name.constantize
    rescue NameError => e
      nil
    end
  end

  def per_page_options
    options_for_select([
      ['5', 5], ['10', 10], ['15', 15], ['20', 20], ['50', 50], ['100', 100]
    ], params.fetch(:per_page, 10))
  end

  def region_options(regime)
    options_for_select([['All', 'all']] +
                       regime.transaction_headers.pluck(:region).
                       sort.map { |r| [r, r] },
                       params.fetch(:region, 'all'))
  end
end
