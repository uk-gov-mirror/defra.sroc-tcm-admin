module TcmConstants
  PeriodDates = {
    pas: {
      attr_name: :header_attr_10,
      format: "%d/%m/%Y"
    },
    cfd: {
      attr_name: :line_attr_3,
      format: "%d/%m/%y"
    },
    # WABS not known yet
    wabs: {
      attr_name: :header_attr_10,
      format: "%d/%m/%Y"
    }
  }.freeze
end
