# frozen_string_literal: true

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
    name.constantize
  rescue NameError
    nil
  end

  def view_options(selected_mode)
    opts = [
      [t("transactions.index.title"), "unbilled",
       { "data-path" => regime_transactions_path(@regime) }],
      [t("history.index.title"), "historic",
       { "data-path" => regime_history_index_path(@regime) }],
      [t("retrospectives.index.title"), "retrospective",
       { "data-path" => regime_retrospectives_path(@regime) }],
      [t("exclusions.index.title"), "excluded",
       { "data-path" => regime_exclusions_path(@regime) }]
    ]

    opts = opts.reject { |o| o[1] == "retrospective" } if @regime.waste?
    opts = opts.reject { |o| o[1] == "excluded" } if current_user.can_read_only?
    options_for_select opts, selected_mode
  end

  def per_page_options(selected = nil)
    selected = param_or_cookie(:per_page, 10) if selected.nil?
    options_for_select([
                         ["5", 5], ["10", 10], ["15", 15], ["20", 20], ["50", 50], ["100", 100]
                       ], selected)
  end

  def available_regions(regime)
    selected = params.fetch(:region, "")

    regime.transaction_headers.distinct.pluck(:region).sort.map { |r| { label: r, value: r, selected: selected == r } }
  end

  def permit_financial_year_options(years_list, selected)
    options_for_select(pretty_years_list(years_list), selected)
  end

  def pretty_years_list(list)
    list = [] if list.nil?
    list.sort.map { |y| ["#{y[0..1]}/#{y[2..3]}", y] }
  end

  def temporary_cessation_options(selected)
    options_for_select([["Y", true], ["N", false]], selected)
  end

  def permit_categories(regime)
    PermitStorageService.new(regime)
                        .active_list_for_selection("1819")
                        .pluck(:code).map do |c|
                          { value: c, label: c }
                        end
  end

  def reason_options(reasons, selected = nil)
    options_for_select(reasons.map { |r| [r, r] }, selected)
  end

  def regime_columns(regime)
    if regime.installations?
      %i[customer_reference
         permit_reference
         sroc_category
         compliance_band
         period
         amount]
    elsif regime.water_quality?
      %i[customer_reference
         consent_reference
         version
         discharge
         sroc_category
         variation
         temporary_cessation
         period
         amount]
    elsif regime.waste?
      %i[customer_reference
         permit_reference
         sroc_category
         compliance_band
         period
         amount]
    else
      raise "Unknown regime #{p regime}"
    end
  end

  def columns_for_regime(regime)
    regime_columns(regime).map do |c|
      { name: c, label: t(c, scope: "table.heading"), sortable: sortable?(c), selectable: selectable?(c) }
    end.to_json
  end

  def history_columns_for_regime(regime)
    regime_columns(regime).map do |c|
      { name: c, label: t(c, scope: "table.heading"), sortable: sortable?(c), selectable: false }
    end.to_json
  end

  def sortable?(col)
    %i[customer_reference permit_reference sroc_category compliance_band
       consent_reference variation].include? col
  end

  def selectable?(col)
    col == :sroc_category
  end

  def confidence(level)
    { green: "High", amber: "Medium", red: "Low" }.fetch(level.to_sym)
  end

  def confidence_dot(level)
    return unless level

    msg = "Category confidence is #{confidence(level)}"

    "<span class='sr-only'>#{msg}</span>" \
      "<span aria-hidden='true' class='#{level}-dot' title='#{msg}'></span>".html_safe
  end

  def lookup_category_description(regime, category, financial_year)
    c = PermitStorageService.new(regime).code_for_financial_year(category, financial_year)
    c&.description
  end

  def approval_check(approved)
    return unless approved

    "<span aria-hidden='true' class='oi oi-check'></span>" \
      "<span class='sr-only'>Approved</span>".html_safe
  end

  def status_text(state)
    {
      billed: "Billed",
      unbilled: "To be billed",
      exporting: "Exporting",
      excluded: "Excluded",
      retrospective: "Pre-SRoC to be billed",
      retro_exporting: "Pre-SRoC Exporting",
      retro_billed: "Pre-SRoC Billed"
    }.fetch(state.to_sym)
  end

  def status_colour(state)
    {
      billed: "success",
      unbilled: "primary",
      exporting: "secondary",
      excluded: "danger",
      retrospective: "warning",
      retro_exporting: "secondary",
      retro_billed: "success"
    }.fetch(state.to_sym)
  end
end
