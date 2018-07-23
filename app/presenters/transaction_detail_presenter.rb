class TransactionDetailPresenter < SimpleDelegator
  include FormattingUtils

  def self.wrap(collection)
    collection.map { |o| new o }
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
    fmt_date transaction_file.created_at
  end

  def generated_file_date
    transaction_file.created_at.strftime("%d/%m/%y") if transaction_file
  end

  def pro_rata_days
    bd = billable_days
    fyd = financial_year_days

    if bd == fyd
      ''
    else
      "#{bd}/#{fyd}"
    end
  end

  def calculated_amount
    tcm_charge
    # charge = (charge_calculation['calculation']['chargeValue'] * 100).round
    # charge = -charge if line_amount.negative?
    # charge
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
    ActiveSupport::NumberHelper.number_to_currency(
          sprintf('%.2f', line_amount/100.0), unit: "")
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

  # def category_description
  #   if category.present?
  #     desc = PermitCategory.find_by(code: category).description
  #     desc.truncate(150, separator: /\s/, ommission: '...')
  #   end
  # end
  
  def baseline_charge
    if charge_calculated? && !charge_calculation_error?
      (charge_calculation['calculation']['decisionPoints']['baselineCharge'] * 100).round
    end
  end

  def region_from_ref
    if tcm_transaction_reference.present?
      tcm_transaction_reference[-2]
    else
      transaction_header.region
    end
  end

  def transaction_date
    # called when exporting to file
    if charge_calculation && charge_calculation['generatedAt']
      charge_calculation['generatedAt'].to_date
    else
      transaction_detail.transaction_date
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
    # year = financial_year - 2000
    #sik76mzz iFY#{year}#{year + 1}"
    "FY#{tcm_financial_year}"
  end

  def period_start
    fmt_date transaction_detail.period_start
  end

  def period_end
    fmt_date transaction_detail.period_end
  end

  def credit_debit_indicator
    line_amount < 0 ? 'C' : 'D'
  end

  def date_received
    fmt_date created_at
  end

  def temporary_cessation_file
    temporary_cessation? ? '50%' : ''
  end

  def temporary_cessation_flag
    temporary_cessation? ? 'Y' : 'N'
  end

  def period
    "#{transaction_detail.period_start.strftime("%d/%m/%y")} - #{transaction_detail.period_end.strftime("%d/%m/%y")}"
  end

  def amount
    if transaction_detail.charge_calculated?
      value = charge_amount
      if value.nil?
        credit_debit
      else
        ActiveSupport::NumberHelper.number_to_currency(
          sprintf('%.2f', value/100.0), unit: "")
      end
    else
      credit_debit
    end
  end

  def credit_debit
    txt = if line_amount.negative?
            'Credit'
          else
            'Invoice'
          end

    txt += ' (TBC)' if status != 'excluded'
    txt
  end

  def charge_amount
    tcm_charge
    # charge = transaction_detail.charge_calculation
    # if charge && charge["calculation"] && charge["calculation"]["messages"].nil?
    #   amt = charge["calculation"]["chargeValue"]
    #   # FIXME: is this the /best/ way to determine a credt?
    #   amt *= -1 if !amt.nil? && line_amount.negative?
    #   amt
    # else
    #   nil
    # end
  end

  def generated_at
    # TODO: replace this with the date *we* generated the file
    fmt_date transaction_detail.transaction_header.generated_at
  end

  def error_message
    TransactionCharge.extract_calculation_error(transaction_detail)
  end

protected
  def transaction_detail
    __getobj__
  end

  def permit_store
    @permit_store ||= PermitStorageService.new(regime)
  end
end
