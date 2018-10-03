module TransactionsHelper
  def present_transaction(transaction)
    name = "#{transaction.regime.slug}_transaction_detail_presenter".camelize
    presenter = str_to_class(name) || TransactionDetailsPresenter
    presenter.new(transaction)
  end

  def transaction_row_class(transaction)
    if transaction.charge_calculation_error?
      "error alert-danger"
    elsif transaction.excluded?
      "excluded"
    else
      "active"
    end
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

  def view_options(selected_mode)
    options_for_select([
      ['Transactions to be billed', 'unbilled', { 'data-path' => regime_transactions_path(@regime) }],
      ['Transaction History', 'historic', { 'data-path' => regime_history_index_path(@regime) }],
      ['Retrospectives to be billed', 'retrospective', { 'data-path' => regime_retrospectives_path(@regime) }],
      ['Excluded Transactions', 'excluded', { 'data-path' => regime_exclusions_path(@regime) }]
    ], selected_mode)
  end

  def per_page_options
    options_for_select([
      ['5', 5], ['10', 10], ['15', 15], ['20', 20], ['50', 50], ['100', 100]
    ], param_or_cookie(:per_page, 10))
  end

  def available_regions(regime)
    selected = params.fetch(:region, '')

    # regions = [{ label: 'All', value: 'all', selected: selected == 'all'}]
    regime.transaction_headers.distinct.pluck(:region).
      sort.map { |r| { label: r, value: r, selected: selected == r } }
  end

  def region_options(regime, include_all = true)
    if include_all
      arr = [['All', 'all']]
      default_region = 'all'
    else
      arr = []
      default_region = ''
    end

    options_for_select(arr + 
                       regime.transaction_headers.pluck(:region).uniq.
                       sort.map { |r| [r, r] },
                       param_or_cookie(:region, default_region))
  end

  # def region_options_historic(regime)
  #   options_for_select([['All', 'all']] +
  #                      regime.transaction_headers.pluck(:region).uniq.
  #                      sort.map { |r| [r, r] },
  #                      params.fetch(:region, 'all'))
  # end

  def financial_year_options(years_list)
    years_list = [] if years_list.nil?
    opts = []

    # show all when nothing available or when more than one item in the list
    opts = [['All', 'all']] if years_list.length != 1
    options_for_select(opts +
                       years_list.sort.map { |y| ["#{y[0..1]}/#{y[2..3]}", y] },
                       @financial_year)
  end

  def category_options(regime, selected)
    options_for_select([['Category 1',1],['Category 2',2]], selected)
  end

  def temporary_cessation_options(selected)
    options_for_select([['Y', true], ['N', false]], selected)
  end

  def permit_categories(regime)
    PermitStorageService.new(regime).active_list_for_selection('1819').
      pluck(:code).map do |c|
        { value: c, label: c }
      end
    # regime.permit_categories.order(:code).pluck(:code).map do |c|
    #   { value: c, label: c }
    # end
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

  def confidence(level)
    { green: 'High', amber: 'Medium', red: 'Low' }.fetch(level.to_sym)
  end

  def confidence_dot(level)
    if level
      msg = "Category confidence is #{confidence(level)}"

      "<span class='sr-only'>#{msg}</span>" \
        "<span aria-hidden='true' class='#{level}-dot' title='#{msg}'></span>".
        html_safe
    end
  end

  def lookup_category_description(regime, category, financial_year)
     c = PermitStorageService.new(regime).
       code_for_financial_year(category, financial_year)
     c.description unless c.nil?
  end

  def status_text(state)
    {
      billed: 'Billed',
      unbilled: 'Unbilled',
      exporting: 'Exporting',
      excluded: 'Excluded',
      retrospective: 'Pre-SRoC Unbilled',
      retro_exporting: 'Pre-SRoC Exporting',
      retro_billed: 'Pre-SRoC Billed'
    }.fetch(state.to_sym)
  end

  def status_colour(state)
    {
      billed: 'success',
      unbilled: 'primary',
      exporting: 'secondary',
      excluded: 'danger',
      retrospective: 'warning',
      retro_exporting: 'secondary',
      retro_billed: 'success'
    }.fetch(state.to_sym)
  end
end
