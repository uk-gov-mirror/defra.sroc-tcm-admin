module FormattingUtils
  def padded_number(val, length = 7)
    val.to_s.rjust(length, "0")
  end

  def fmt_date(dt)
    dt.strftime("%-d-%^b-%Y")
  end

  def pence_to_currency(val)
    ActiveSupport::NumberHelper.number_to_currency(
                      sprintf("%.2f", val/100.0), unit: "")
  end
end
