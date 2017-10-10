class CfdTransactionDetailPresenter < TransactionDetailPresenter
  def variation_percentage
    line_attr_9
  end

  def consent_reference
    "#{permit_reference}/#{version}/#{discharge_reference}"
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

  def period
    line_attr_3
  end
end
