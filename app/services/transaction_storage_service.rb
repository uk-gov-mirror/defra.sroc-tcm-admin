# frozen_string_literal: true

class TransactionStorageService
  attr_reader :user, :regime

  def initialize(regime, user = nil)
    # when instantiated from a controller the 'current_user' should
    # be passed in. This will allow us to audit actions etc. down the line.
    @regime = regime
    @user = user
  end

  def find(id)
    regime.transaction_details.find(id)
  end

  def transactions_to_be_billed(search = '', page = 1, per_page = 10,
                                region = '', order = :customer_reference,
                                direction = 'asc')
    region = first_region if region.blank?
    q = regime.transaction_details.region(region).unbilled
    q = q.search(search) unless search.blank?
    order_query(q, order, direction).page(page).per(per_page)
  end

  def transactions_to_be_billed_for_export(search = '', region = '',
                                           order = :customer_reference,
                                           direction = 'asc')
    region = first_region if region.blank?
    q = regime.transaction_details.region(region).unbilled
    q = q.search(search) unless search.blank?
    order_query(q, order, direction)
  end

  def transaction_history(search = '', fy = '', page = 1, per_page = 10, region = '',
                               order = :customer_reference, direction = 'asc')
    q = regime.transaction_details.historic
    q = q.region(region) unless region.blank?
    q = q.history_search(search) unless search.blank?
    q = q.where(tcm_financial_year: fy) unless fy.blank?
    order_query(q, order, direction).page(page).per(per_page)
  end

  def transaction_history_for_export(search = '', fy = '', region = '',
                                     order = :customer_reference, direction = 'asc')
    q = regime.transaction_details.historic
    q = q.region(region) unless region.blank?
    q = q.history_search(search) unless search.blank?
    q = q.where(tcm_financial_year: fy) unless fy.blank?
    order_query(q, order, direction)
  end

  def retrospective_transactions(search = '', page = 1, per_page = 10,
                                 region = '', order = :customer_reference,
                                 direction = 'asc')
    region = first_retrospective_region if region.blank?
    q = regime.transaction_details.region(region).retrospective
    q = q.retrospective_search(search) unless search.blank?
    order_query(q, order, direction).page(page).per(per_page)
  end

  def excluded_transactions(search = '', fy = '', page = 1, per_page = 10,
                            region = '', order = :customer_reference,
                            direction = 'asc')
    q = regime.transaction_details.historic_excluded
    q = q.region(region) unless region.blank?
    q = q.exclusion_search(search) unless search.blank?
    q = q.where(tcm_financial_year: fy) unless fy.blank?
    order_query(q, order, direction).page(page).per(per_page)
  end

  def unbilled_regions
    regions_for('unbilled')
  end

  def history_regions
    regions_for('billed')
  end
  
  def retrospective_regions
    regions_for('retrospective')
  end

  def exclusion_regions
    regions_for('excluded')
  end

  def regions_for(status)
    regime.transaction_headers.joins(:transaction_details).
      merge(TransactionDetail.where(status: status)).
      distinct.order(:region).pluck(:region).reject { |r| r.blank? }
  end

  def unbilled_financial_years
    financial_years_for('unbilled')
  end

  def history_financial_years
    financial_years_for('billed')
  end

  def retrospective_financial_years
    financial_years_for('retrospective')
  end

  def exclusion_financial_years
    financial_years_for('excluded')
  end

  def financial_years_for(status)
    regime.transaction_details.where(status: status).
      distinct.order(:tcm_financial_year).pluck(:tcm_financial_year)
  end

  def first_region
    unbilled_regions.first
  end

  def first_history_region
    history_regions.first
  end

  def first_retrospective_region
    retrospective_regions.first
  end

  def first_exclusion_region
    exclusion_regions.first
  end

  def order_query(q, col, dir)
    dir = dir == 'desc' ? :desc : :asc
    txt_dir = (dir == :asc) ? 'asc' : 'desc'

    # lookup col value
    case col.to_sym
    when :customer_reference
      q.order(customer_reference: dir, id: dir)
    when :original_filename
      q.order(original_filename: dir, customer_reference: dir)
    when :original_file_date
      q.order(original_file_date: dir, original_filename: dir)
    when :transaction_reference
      q.order(transaction_reference: dir, id: dir)
    when :transaction_date
      q.order(transaction_date: dir, id: dir)
    when :permit_reference
      q.order(reference_1: dir, id: dir)
    when :original_permit_reference
      q.order(reference_2: dir, id: dir)
    when :consent_reference
      q.order(reference_1: dir, reference_2: dir, reference_3: dir, id: dir)
    when :sroc_category
      q.order(category: dir, id: dir)
    when :compliance_band
      if regime.installations?
        q.order(line_attr_11: dir, id: dir)
      else
        q.order(line_attr_6: dir, reference_1: dir)
      end
    # when :variation
    #   q.order(line_attr_9: dir, id: dir)
    when :variation
      q.order("to_number(variation, '999%') #{txt_dir}")
    when :period
      q.order(period_start: dir, period_end: dir, id: dir)
    when :tcm_transaction_reference
      q.order(tcm_transaction_reference: dir, id: dir)
    when :version
      q.order(reference_2: dir, reference_1: dir)
    when :discharge
      q.order(reference_3: dir, reference_1: dir)
    when :original_filename
      q.order(original_filename: dir, id: dir)
    when :generated_filename
      q.order(generated_filename: dir, id: dir)
    when :generated_file_date
      q.includes(:transaction_file).
        order("transaction_files.created_at #{dir}, tcm_transaction_reference #{dir}")
    when :amount
      q.order(tcm_charge: dir, id: dir)
    when :excluded_reason
      q.order(excluded_reason: dir, reference_1: dir)
    when :temporary_cessation
      q.order(temporary_cessation: dir, reference_1: dir)
    else
      q.joins(:transaction_header).
        merge(TransactionHeader.order(region: dir, file_sequence_number: dir)).
        order(transaction_reference: dir, id: dir)
    end
  end

  def summary_presenter
    if regime.water_quality?
      CfdTransactionSummaryPresenter.new(regime)
    elsif regime.waste?
      WmlTransactionSummaryPresenter.new(regime)
    else
      PasTransactionSummaryPresenter.new(regime)
    end
  end
end
