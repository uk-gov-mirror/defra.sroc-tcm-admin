require 'csv'

class PermitCategoryImporter
  def self.import(regime, filename)
    n = regime.permit_categories.count
    CSV.foreach(filename, headers: false) do |row|
      code = row[0]
      desc = row[1]
      order = n
      n += 1
      regime.permit_categories.find_or_create_by!(code: code) do |cat|
        cat.description = desc
        cat.display_order = order
        cat.status = "active"
      end
    end
  end
end
