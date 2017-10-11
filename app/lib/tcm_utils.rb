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
end
