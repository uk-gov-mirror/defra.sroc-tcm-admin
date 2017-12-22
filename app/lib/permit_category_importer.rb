require 'csv'

class PermitCategoryImporter
  def self.import(regime, filename)
    n = regime.permit_categories.count
    destroy_BOM = true
    CSV.foreach(filename, headers: false) do |row|
      code = row[0]
      desc = row[1]
      order = n
      if destroy_BOM
        code = code.force_encoding('utf-8')
        code.gsub!("\xEF\xBB\xBF".force_encoding('utf-8'), '')
        destroy_BOM = false
      end
      n += 1
      regime.permit_categories.find_or_create_by!(code: code) do |cat|
        cat.description = desc
        cat.display_order = order
        cat.status = "active"
      end
    end
  end
end
