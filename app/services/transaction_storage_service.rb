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

  def transactions_to_be_billed(search = '', page = 1, per_page = 10, region = '',
                               order = :customer_reference, direction = 'asc')
    region = first_region if region.blank?
    q = regime.transaction_details.region(region).unbilled
    q = q.search(search) unless search.blank?
    order_query(q, order, direction).page(page).per(per_page)
  end

  # def transactions_related_to(transaction)
  #   # col = regime.waste_or_installations? ? :reference_3 : :reference_1
  #   # val = transaction.send(col)
  #   # regime.transaction_details.unbilled.where(col => val).
  #   #   where.not(col => nil).
  #   #   where.not(col => 'NA').
  #   #   order(:reference_1)
  #   at = TransactionDetail.arel_table
  #   q = regime.transaction_details.unbilled
  #   if regime.waste_or_installations?
  #     q = q.where.not(reference_3: nil).
  #       where.not(reference_3: 'NA').
  #       where(reference_3: transaction.reference_3).
  #       or(q.where.not(reference_1: 'NA').
  #          where.not(reference_1: nil).
  #          where(reference_1: transaction.reference_1)
  #       ).
  #       or(q.where.not(reference_2: 'NA').
  #          where.not(reference_2: nil).
  #          where(reference_2: transaction.reference_2)
  #       )
  #   else
  #     q = q.where.not(reference_1: nil).
  #       where.not(reference_1: 'NA').
  #       where(reference_1: transaction.reference_1)
  #   end
  #   q.order(:reference_1)
  # end

  def transaction_history(search = '', page = 1, per_page = 10, region = 'all',
                          order = :file_reference, direction = 'asc')
    q = regime.transaction_details.region(region).historic
    q = q.search(search) unless search.blank?
    order_query(q, order, direction).page(page).per(per_page)
    # q.order(order_args(order, direction)).page(page).per(per_page)
  end

  # def transactions_to_be_billed_summary(region)
  #   summary_presenter.summarize(region)
  # end
  #
  def first_region
    regime.transaction_headers.distinct.order(:region).pluck(:region).first
  end

  def order_query(q, col, dir)
    dir = dir == 'desc' ? :desc : :asc
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
      q.order(line_attr_11: dir, id: dir)
    when :variation
      q.order(line_attr_9: dir, id: dir)
    when :period
      q.order(period_start: dir, period_end: dir, id: dir)
    else
      # file reference
      # TODO: once we have real data this is the one
      # q.order(generated_filename: dir, transaction_reference: dir)

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
