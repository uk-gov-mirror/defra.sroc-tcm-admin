class WmlTransactionDetailPresenter < TransactionDetailPresenter
  def charge_params
    {
      permitCategoryRef: category,
      # percentageAdjustment: clean_variation_percentage,
      temporaryCessation: temporary_cessation,
      compliancePerformanceBand: compliance_band,
      billableDays: billable_days,
      financialDays: financial_year_days,
      chargePeriod: charge_period,
      preConstruction: false,
      environmentFlag: 'TEST'
    }
  end

  def compliance_band
    band = line_attr_6.first if line_attr_6.present?
    band || ""
  end

  def permit_reference
    reference_1
  end

  def credit_line_description
    if transaction_detail.line_description.present?
      txt = transaction_detail.line_description
      pos = txt.index /\sdue\s/
      if pos
        "Credit of subsistence charge for permit category #{category}" +
          txt[pos..-1].gsub(/Permit Ref:/, 'EPR Ref:')
      else
        ""
      end
    end
  end

  def credit_line_attr_2
  end

  def credit_line_attr_3
  end

  def as_json(options = {})
    {
      id: id,
      customer_reference: customer_reference,
      permit_reference: permit_reference,
      compliance_band: compliance_band,
      sroc_category: category,
      temporary_cessation: temporary_cessation_flag,
      period: period,
      amount: amount,
      error_message: error_message
    }
  end

  def extract_errors
    if errors[:category].any?
      errors.full_messages_for(:category)
    elsif errors[:base].any?
      errors.full_messages_for(:base)
    elsif charge_calculation_error?
      charge_calculation["calculation"]["messages"]
    else
      nil
    end
  end
end
