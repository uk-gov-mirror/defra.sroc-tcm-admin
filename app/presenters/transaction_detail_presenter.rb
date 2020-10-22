# frozen_string_literal: true

class TransactionDetailPresenter < SimpleDelegator
  include FormattingUtils

  def initialize(obj, user = nil)
    super obj
    @user = user
  end

  def self.wrap(collection, user = nil)
    collection.map { |o| new(o, user) }
  end

  def editable?
    # NOTE: need user for this
    unbilled? && !excluded? && !approved?
  end

  def file_reference
    transaction_detail.transaction_header.file_reference
  end

  def billable_days
    (transaction_detail.period_end.to_date - transaction_detail.period_start.to_date).to_i + 1
  end

  def original_file_date_table
    transaction_detail.original_file_date.strftime("%d/%m/%y")
  end

  def original_file_date
    fmt_date transaction_detail.original_file_date
  end

  def tcm_file_date
    if transaction_file
      fmt_date transaction_file.created_at
    else
      ""
    end
  end

  def generated_file_date
    generated_file_at&.strftime("%d/%m/%y")
  end

  def pro_rata_days
    bd = billable_days
    fyd = financial_year_days

    if bd == fyd
      ""
    else
      "#{bd}/#{fyd}"
    end
  end

  def calculated_amount
    tcm_charge
  end

  def currency_line_amount
    pence_to_currency(transaction_detail.line_amount)
  end

  def currency_unit_of_measure_price
    pence_to_currency(transaction_detail.unit_of_measure_price)
  end

  def currency_baseline_charge
    return "" if baseline_charge.nil?

    pence_to_currency(baseline_charge)
  end

  def currency_tcm_charge
    return "" if transaction_detail.tcm_charge.nil?

    pence_to_currency(transaction_detail.tcm_charge)
  end

  def original_charge
    pence_to_currency(line_amount)
  end

  def category_description
    desc = transaction_detail.category_description
    return desc unless desc.blank?

    # category description is not present until the user generates
    # a transaction file. However, is should probably be included
    # in a TTBB export if a category has been set even at the risk
    # of the category description changing between assignment and
    # file generation
    if transaction_detail.unbilled? && category.present?
      pc = permit_store.code_for_financial_year(category, tcm_financial_year)
      desc = pc.description unless pc.nil?
    end
    desc
  end

  def category_locked
    transaction_detail.suggested_category&.admin_lock?
  end

  def can_update_category?
    if category_locked
      # if the current_user is an admin we can allow editing
      @user&.admin?
    else
      true
    end
  end

  def baseline_charge
    return unless charge_calculated? && !charge_calculation_error?

    (charge_calculation["calculation"]["decisionPoints"]["baselineCharge"] * 100).round
  end

  def transaction_date
    # called when exporting to file
    if charge_calculation && charge_calculation["generatedAt"]
      charge_calculation["generatedAt"].to_date
    else
      transaction_detail.transaction_date
    end
  end

  def original_transaction_date
    transaction_detail.transaction_date.to_date
  end

  def pre_sroc_flag
    retrospective? || billed_retrospective? ? "Y" : "N"
  end

  def excluded_flag
    permanently_excluded? || excluded? ? "Y" : "N"
  end

  def excluded_reason
    if permanently_excluded? || excluded?
      transaction_detail.excluded_reason
    else
      ""
    end
  end

  def financial_year_days
    year = financial_year
    start_date = Date.new(year, 4, 1)
    end_date = Date.new(year + 1, 3, 31)
    (end_date - start_date).to_i + 1
  end

  def financial_year
    dt = transaction_detail.period_start
    dt.month < 4 ? dt.year - 1 : dt.year
  end

  def charge_period
    "FY#{tcm_financial_year}"
  end

  def period_start
    fmt_date transaction_detail.period_start
  end

  def period_end
    fmt_date transaction_detail.period_end
  end

  def credit_debit_indicator
    line_amount.negative? ? "C" : "D"
  end

  def date_received
    fmt_date created_at
  end

  def temporary_cessation_file
    temporary_cessation? ? "50%" : ""
  end

  def temporary_cessation_flag
    temporary_cessation? ? "Y" : "N"
  end

  def temporary_cessation_yes_no
    temporary_cessation ? "Yes" : "No"
  end

  def period
    "#{transaction_detail.period_start.strftime('%d/%m/%y')} - #{transaction_detail.period_end.strftime('%d/%m/%y')}"
  end

  def amount
    if transaction_detail.charge_calculated?
      value = charge_amount
      if value.nil?
        credit_debit
      else
        ActiveSupport::NumberHelper.number_to_currency(
          format("%<value>.2f", value: (value / 100.0)), unit: ""
        )
      end
    else
      credit_debit
    end
  end

  def credit_debit
    txt = if line_amount.negative?
            "Credit"
          else
            "Debit"
          end

    txt += " (TBC)" unless status == "excluded"
    txt
  end

  def pretty_status
    status.to_s.capitalize
  end

  def charge_amount
    tcm_charge
  end

  def generated_at
    # TODO: replace this with the date *we* generated the file
    fmt_date transaction_detail.transaction_header.generated_at
  end

  def error_message
    TransactionCharge.extract_calculation_error(transaction_detail)
  end

  def suggested_category_code
    suggested_category&.category
  end

  def suggested_category_confidence_level
    suggested_category&.confidence_level&.titlecase
  end

  def suggested_category_overridden_flag
    suggested_category&.overridden ? "Y" : "N"
  end

  def suggested_category_admin_lock_flag
    suggested_category&.admin_lock ? "Y" : "N"
  end

  def suggested_category_logic
    suggested_category&.logic
  end

  def suggested_category_stage
    suggested_category&.suggestion_stage
  end

  def approved_flag
    transaction_detail.approved_for_billing ? "Y" : "N"
  end

  def approved_date
    approved_for_billing_at
  end

  def tcm_compliance_percentage
    band = extract_compliance_performance
    return "" if band.blank? || band == "()"

    d = band.match(/\A.*\((\d+%)\)\z/)
    d && d.size == 2 ? d[1] : ""
  end

  def confidence_level
    transaction_detail.suggested_category&.confidence_level
  end

  def customer_name
    if transaction_detail.customer_name.present?
      transaction_detail.customer_name
    else
      ""
    end
  end

  protected

  def transaction_detail
    __getobj__
  end

  def extract_compliance_performance
    chg = transaction_detail.charge_calculation
    chg["calculation"]["compliancePerformanceBand"] unless chg.nil? ||
                                                           chg["calculation"].nil?
  end

  def permit_store
    @permit_store ||= PermitStorageService.new(regime)
  end
end
