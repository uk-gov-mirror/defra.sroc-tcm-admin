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

  def transactions_to_be_billed(search = '', page = 1, per_page = 10, region = 'all',
                               order = :customer_reference, direction = 'asc')
    q = regime.transaction_details.region(region).unbilled
    q = q.search(search) unless search.blank?
    order_query(q, order, direction).page(page).per(per_page)
  end

  def transactions_related_to(transaction)
    # col = regime.waste_or_installations? ? :reference_3 : :reference_1
    # val = transaction.send(col)
    # regime.transaction_details.unbilled.where(col => val).
    #   where.not(col => nil).
    #   where.not(col => 'NA').
    #   order(:reference_1)
    at = TransactionDetail.arel_table
    q = regime.transaction_details.unbilled
    if regime.waste_or_installations?
      q = q.where.not(reference_3: nil).
        where.not(reference_3: 'NA').
        where(reference_3: transaction.reference_3).
        or(q.where.not(reference_1: 'NA').
           where.not(reference_1: nil).
           where(reference_1: transaction.reference_1)
        ).
        or(q.where.not(reference_2: 'NA').
           where.not(reference_2: nil).
           where(reference_2: transaction.reference_2)
        )
    else
      q = q.where.not(reference_1: nil).
        where.not(reference_1: 'NA').
        where(reference_1: transaction.reference_1)
    end
    q.order(:reference_1)
  end

  def transaction_history(search = '', page = 1, per_page = 10, region = 'all',
                          order = :file_reference, direction = 'asc')
    q = regime.transaction_details.region(region).historic
    q = q.search(search) unless search.blank?
    order_query(q, order, direction).page(page).per(per_page)
    # q.order(order_args(order, direction)).page(page).per(per_page)
  end

  def transactions_to_be_billed_summary(q = '', region = 'all')
    summary = OpenStruct.new
    credits = regime.transaction_details.region(region).unbilled.credits
    invoices = regime.transaction_details.region(region).unbilled.invoices

    if q.present?
      credits = credits.search(q)
      invoices = invoices.search(q)
    end
    credits = credits.pluck(:line_amount)
    invoices = invoices.pluck(:line_amount)

    summary.credit_count = credits.length
    summary.credit_total = credits.sum
    summary.invoice_count = invoices.length
    summary.invoice_total = invoices.sum
    summary.net_total = summary.invoice_total + summary.credit_total
    summary
  end

  def order_query(q, col, dir)
    dir = dir == 'desc' ? :desc : :asc
    # lookup col value
    case col.to_sym
    when :customer_reference
      q.order(customer_reference: dir)
    when :transaction_reference
      q.order(transaction_reference: dir)
    when :permit_reference
      q.order(reference_1: dir)
    when :consent_reference
      q.order(reference_1: dir, reference_2: dir, reference_3: dir)
    when :sroc_category
      # FIXME: not implemented this one yet
      q.order(category: dir)
    when :compliance_band
      q.order(line_attr_11: dir)
    when :variation
      q.order(line_attr_9: dir)
    else
      # file reference
      # TODO: once we have real data this is the one
      # q.order(generated_filename: dir, transaction_reference: dir)

      q.joins(:transaction_header).
        merge(TransactionHeader.order(region: dir, file_sequence_number: dir)).
        order(transaction_reference: dir)
    end
  end
end
