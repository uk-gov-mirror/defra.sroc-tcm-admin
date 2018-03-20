module FormattingUtils
  def padded_number(val, length = 7)
    val.to_s.rjust(length, "0")
  end

  def fmt_date(dt)
    dt.strftime("%-d-%^b-%Y")
  end
end
