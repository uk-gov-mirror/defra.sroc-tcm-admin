class PasTransactionDetailPresenter < TransactionDetailPresenter
  def compliance_band
    "pas comp band"
  end

  def permit_reference
    reference_1 || 'todo'
  end

  def period
    header_attr_10
  end
end
