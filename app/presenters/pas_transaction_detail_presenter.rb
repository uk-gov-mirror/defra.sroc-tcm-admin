class PasTransactionDetailPresenter < TransactionDetailPresenter
  def charge_params
    {
      permitCategoryRef: category,
      temporaryCessation: temporary_cessation,
      # percentageAdjustment: 100,
      compliancePerformanceBand: compliance_band,
      billableDays: billable_days,
      financialDays: financial_year_days,
      chargePeriod: charge_period,
      preConstruction: false,
      environmentFlag: 'TEST'
    }
  end

  def compliance_band
    band = line_attr_11.first if line_attr_11.present?
    band || ""
  end

  def permit_reference
    reference_1
  end

  def original_permit_reference
    reference_2
  end

  def site
    header_attr_3
  end

  def as_json(options = {})
    {
      id: id,
      customer_reference: customer_reference,
      permit_reference: permit_reference,
      original_permit_reference: original_permit_reference,
      compliance_band: compliance_band,
      site: site,
      sroc_category: category,
      temporary_cessation: temporary_cessation_flag,
      period: period,
      amount: amount
    }
  end
end
