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

  def clean_variation_percentage
    return 100 if variation_percentage.blank?
    variation_percentage.gsub(/%/,'')
  end

  def variation_percentage
    variation || line_attr_9
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
    line_attr_1
  end

  # def period
  #   line_attr_3
  # end

  def as_json(options = {})
    {
      id: id,
      customer_reference: customer_reference,
      consent_reference: consent_reference,
      version: version,
      discharge: discharge_reference,
      sroc_category: category,
      variation: clean_variation_percentage,
      temporary_cessation: temporary_cessation_flag,
      period: period,
      amount: amount
    }
  end
end
