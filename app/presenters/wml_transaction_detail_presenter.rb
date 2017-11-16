class WmlTransactionDetailPresenter < TransactionDetailPresenter
  def compliance_band
    band = line_attr_6.first if line_attr_6.present?
    band || ""
  end

  def permit_reference
    reference_1
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
      amount: amount
    }
  end
end
