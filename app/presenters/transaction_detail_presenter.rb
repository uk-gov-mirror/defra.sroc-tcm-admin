class TransactionDetailPresenter < SimpleDelegator
  include FormattingUtils

  def self.wrap(collection)
    collection.map { |o| new o }
  end

  def file_reference
    transaction_detail.transaction_header.file_reference
  end

  def billable_days
    (period_end.to_date - period_start.to_date).to_i + 1
  end

  def calculated_amount
    tcm_charge
    # charge = (charge_calculation['calculation']['chargeValue'] * 100).round
    # charge = -charge if line_amount.negative?
    # charge
  end

  def category_description
    desc = PermitCategory.find_by(code: category).description
    desc.truncate(150, separator: /\s/, ommission: '...')
  end
  
  def baseline_charge
    (charge_calculation['calculation']['decisionPoints']['baselineCharge'] * 100).round
  end

  def region_from_ref
    if tcm_transaction_reference.present?
      tcm_transaction_reference[-2]
    else
      transaction_header.region
    end
  end

  def transaction_date
    # called when exporting to file, so charge should've been calculated
    charge_calculation['generatedAt'].to_date
  end

  def financial_year_days
    year = financial_year
    start_date = Date.new(year, 4, 1)
    end_date = Date.new(year + 1, 3, 31)
    (end_date - start_date).to_i + 1
  end

  def financial_year
    period_start.month < 4 ? period_start.year - 1 : period_start.year
  end

  def charge_period
    # year = financial_year - 2000
    # "FY#{year}#{year + 1}"
    "FY#{tcm_financial_year}"
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
    "#{period_start.strftime("%d/%m/%y")} - #{period_end.strftime("%d/%m/%y")}"
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
    if line_amount.negative?
      'Credit (TBC)'
    else
      'Invoice (TBC)'
    end
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

protected
  def transaction_detail
    __getobj__
  end
end
