class TcmUtils
  def self.obsfucate_sites
    Regime.all.each do |regime|
      attr = regime.waste_or_installations? ? :header_attr_3 : :line_attr_1
      regime.transaction_details.distinct.pluck(attr).each do |site|
        regime.transaction_details.where(attr => site).
          update_all(attr => generate_site_name)
      end
    end
  end

  def self.generate_site_name
    a = %w[ High Low Narrow Broad East West North South White Brown Green Red ]
    b = %w[ St. Rd. Chigley Trumpton Camberwick Tottenham Bristol Cliff Sea Beach Windmill ]
    c = %w[ Waste Water Smelting Pig Sewerage Hill Wigwam Chipmonk Haystack ]
    d = %w[ Disposal Facility Farm Unit Incinerator Plant Wharf Tank ]
    "#{a.sample} #{b.sample} #{c.sample} #{d.sample}"
  end

  def self.set_period_dates()
    Regime.all.each do |r|
      r.transaction_details.each do |t|
        dates = self.extract_transaction_period_dates(t, r)
        if dates.present?
          t.update_attributes(period_start: dates[0], period_end: dates[1])
        end
      end
    end
  end

  def self.extract_transaction_period_dates(transaction, regime = nil)
    regime = transaction.regime if regime.nil?
    info = TcmConstants::PeriodDates[regime.slug.to_sym]
    self.extract_period_dates(transaction.send(info[:attr_name]), info[:format])
  end

  def self.extract_csv_period_dates(regime, row)
    info = TcmConstants::PeriodDates[regime.slug.to_sym]
    period_index = "TransactionFile::Detail::#{info[:attr_name].to_s.classify}".constantize 
    if regime.waste?
      self.extract_waste_period_dates(row[period_index], info[:format])
    else
      self.extract_period_dates(row[period_index], info[:format])
    end
  end

  def self.extract_waste_period_dates(period, date_format)
    # expecting a string with 2 dates matching the date_format
    # or 'From' and a date matching the date_format
    # e.g.
    # '23/06/2017 - 31/03/2017'
    # 'From 03/10/2017'
    parts = period.split(' ')
    if parts[0].downcase == 'from'
      dates = []
      start_date = Date.strptime(parts[1], date_format)
      end_year = start_date.month > 3 ? start_date.year + 1 : start_date.year
      dates[0] = start_date
      dates[1] = Date.new(end_year, 3, 31)
      dates
    else
      self.extract_period_dates(period, date_format)
    end
  end

  def self.extract_period_dates(period, date_format)
    dates = []
    # expecting a string with 2 dates matching the date_format
    # e.g.
    # '10/06/17 - 22/12/17' 
    # '23/06/2017 - 31/03/2017'
    period.split(' ').select { |i| i != '-' }.each do |d|
      dates << Date.strptime(d, date_format)
    end
    dates
  end
end
