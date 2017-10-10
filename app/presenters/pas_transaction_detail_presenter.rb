class PasTransactionDetailPresenter < TransactionDetailPresenter
  def compliance_band
    line_attr_11.present? ? line_attr_11.first : ""
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

  def period
    header_attr_10
  end
end
