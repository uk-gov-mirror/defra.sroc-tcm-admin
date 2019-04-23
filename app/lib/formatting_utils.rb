module FormattingUtils
  def yn_flag(bool)
    bool ? 'Y' : 'N'
  end

  def padded_number(val, length = 7)
    val.to_s.rjust(length, "0")
  end

  def fmt_date(dt)
    dt.strftime("%-d-%^b-%Y")
  end

  def formatted_pence(value)
    number_to_currency(value / 100.0)
  end

  def formatted_pence_without_symbol(value)
    number_to_currency(value / 100.0, format: "%n") unless value.blank?
  end

  def slash_formatted_date(date, include_time = false)
    format_date(date, "%d/%m/%y", include_time)
  end

  def formatted_date(date, include_time = false)
    format_date(date, "%d-%b-%Y", include_time)
  end

  def format_date(date, fmt, include_time)
    fmt = fmt + " %H:%M:%S" if include_time
    date.strftime(fmt)
  end

  def pence_to_currency(val)
    ActiveSupport::NumberHelper.number_to_currency(
                      sprintf("%.2f", val/100.0), unit: "")
  end
end
