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

  def available_regions(regime)
    selected = params.fetch(:region, 'all')

    regions = [{ label: 'All', value: 'all', selected: selected == 'all'}]
    regions + regime.transaction_headers.distinct.pluck(:region).
      sort.map { |r| { label: r, value: r, selected: selected == r } }
  end

  def region_options(regime)
    options_for_select([['All', 'all']] +
                       regime.transaction_headers.pluck(:region).uniq.
                       sort.map { |r| [r, r] },
                       params.fetch(:region, 'all'))
  end

  def region_options_historic(regime)
    options_for_select([['All', 'all']] +
                       regime.transaction_headers.pluck(:region).uniq.
                       sort.map { |r| [r, r] },
                       params.fetch(:region, 'all'))
  end

  def category_options(regime, selected)
    options_for_select([['Category 1',1],['Category 2',2]], selected)
  end

  def permit_categories(regime)
    regime.permit_categories.order(:display_order, :code).pluck(:code).map do |c|
      { value: c, label: c }
    end
  end

  def regime_columns(regime)
    if regime.installations?
      [ :customer_reference,
        :permit_reference,
        :sroc_category,
        :compliance_band,
        :period,
        :amount ]
    elsif regime.water_quality?
      [ :customer_reference,
        :consent_reference,
        :version,
        :discharge,
        :sroc_category,
        :variation,
        :temporary_cessation,
        :period,
        :amount ]
    elsif regime.waste?
      [ :customer_reference,
        :permit_reference,
        :sroc_category,
        :compliance_band,
        :period,
        :amount ]
    else
      raise "Unknown regime #{p regime}"
    end
  end

  def columns_for_regime(regime)
    regime_columns(regime).map { |c| { name: c, label: t(c, scope: 'table.heading'), sortable: sortable?(c), selectable: selectable?(c) }}.to_json
  end

  def history_columns_for_regime(regime)
    regime_columns(regime).map { |c| { name: c, label: t(c, scope: 'table.heading'), sortable: sortable?(c), selectable: false }}.to_json
  end

  def sortable?(col)
    [:customer_reference, :permit_reference, :sroc_category, :compliance_band,
     :consent_reference, :variation].include? col
  end

  def selectable?(col)
    col == :sroc_category
  end
end
