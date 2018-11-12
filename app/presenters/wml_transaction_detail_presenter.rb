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

  def site
    @site ||= extract_site_from_description
  end

  def credit_line_description
    if transaction_detail.line_description.present?
      txt = transaction_detail.line_description.gsub(/Permit Ref:/, 'EPR Ref:')
      prefix = "Credit of subsistence charge for permit category #{category}"
      pos = txt.index /\sdue\s/
      if pos
        prefix + txt[pos..-1]
      else
        pos = txt.index /\sat\s/
        if pos
          prefix + '. At ' + txt[(pos + 4)..-1]
        else
          m = /\AIn cancellation of invoice no. [A-Z0-9]+:\s*(.*)\z/.match(txt)
          if m
            prefix + '. ' + m[1]
          else
            prefix + '. ' + txt
          end
        end
      end
    end
  end

  def invoice_line_description
    if transaction_detail.line_description.present?
      txt = transaction_detail.line_description.gsub(/Permit Ref:/, 'EPR Ref:')
      # remove leading text either "Compliance Adjustment at " or "Charge code n at "
      pos = txt.index /\sat\s/
      if pos
        "Site: " + txt[(pos + 4)..-1]
      else
        txt
      end
    end
  end

  def compliance_band_with_percent
    val = ""
    chg = transaction_detail.charge_calculation
    if !chg.nil? && !chg['calculation'].nil?
      band = chg['calculation']['compliancePerformanceBand']
      unless band.nil?
        d = band.match /\A(.*)(\(\d+%\))\z/
        val = "#{d[1]} #{d[2]}" if d.size == 3 && d[1].strip.present?
      end
    end
    val
  end

  def temporary_cessation_adjustment
    # FIXME: this should be built using data returned from rules engine
    temporary_cessation ? "50%" : ""
  end

  def extract_site_from_description
    if transaction_detail.line_description.present?
      m = transaction_detail.line_description.match /\Wat\W(.*),\s/
      m.nil? ? "" : m[1]
    else
      ""
    end
  end

  def as_json(options = {})
    {
      id: id,
      customer_reference: customer_reference,
      tcm_transaction_reference: tcm_transaction_reference,
      generated_filename: generated_filename,
      generated_file_date: generated_file_date,
      original_filename: original_filename,
      original_file_date: original_file_date_table,
      permit_reference: permit_reference,
      compliance_band: compliance_band,
      sroc_category: category,
      confidence_level: confidence_level,
      category_locked: category_locked,
      can_update_category: can_update_category?,
      temporary_cessation: temporary_cessation_flag,
      tcm_financial_year: tcm_financial_year,
      period: period,
      amount: amount,
      excluded: excluded,
      excluded_reason: excluded_reason,
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
