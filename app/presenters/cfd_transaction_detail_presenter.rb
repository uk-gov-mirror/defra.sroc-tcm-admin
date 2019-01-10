class CfdTransactionDetailPresenter < TransactionDetailPresenter
  def charge_params
    {
      permitCategoryRef: category,
      percentageAdjustment: clean_variation_percentage,
      temporaryCessation: temporary_cessation,
      compliancePerformanceBand: 'B',
      billableDays: billable_days,
      financialDays: financial_year_days,
      chargePeriod: charge_period,
      preConstruction: false,
      environmentFlag: 'TEST'
    }
  end

  def transaction_date
    transaction_detail.transaction_date.strftime("%d-%^b-%Y")
  end

  def clean_variation_percentage
    return 100 if variation_percentage.blank?
    variation_percentage.gsub(/%/,'')
  end

  def variation_percentage
    variation # || line_attr_9
  end

  def variation_percentage_file
    val = variation_percentage
    return "" if val == '100%'
    val
  end

  def consent_reference
    reference_1
    # "#{permit_reference}/#{version}/#{discharge_reference}"
  end

  def permit_reference
    reference_1
  end

  def version
    reference_2
  end

  def discharge_reference
    reference_3
  end

  def discharge_description
    line_attr_2
  end

  def site
    line_attr_1 || ""
  end

  def discharge_location
    "Discharge Location: #{site}"
  end

  # def period
  #   line_attr_3
  # end

  def as_json(options = {})
    {
      id: id,
      customer_reference: customer_reference,
      tcm_transaction_reference: tcm_transaction_reference,
      generated_filename: generated_filename,
      generated_file_date: generated_file_date,
      original_filename: original_filename,
      original_file_date: original_file_date_table,
      consent_reference: consent_reference,
      version: version,
      discharge: discharge_reference,
      sroc_category: category,
      confidence_level: confidence_level,
      category_locked: category_locked,
      can_update_category: can_update_category?,
      variation: clean_variation_percentage,
      temporary_cessation: temporary_cessation_flag,
      financial_year: charge_period,
      tcm_financial_year: tcm_financial_year,
      region: region,
      period: period,
      line_amount: original_charge,
      amount: amount,
      excluded: excluded,
      excluded_reason: excluded_reason,
      error_message: error_message
    }
  end
end
