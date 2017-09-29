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
    regime.transactions.find(id)
  end

  def transactions_to_be_billed(search = '', page = 1, per_page = 10, region = 'all')
    q = regime.transaction_details.region(region).unbilled
    q = q.search(search) unless search.blank?
    q.order(:transaction_header_id, :sequence_number).page(page).per(per_page)
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
end
