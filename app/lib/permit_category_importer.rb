# frozen_string_literal: true

require "csv"

class PermitCategoryImporter
  def self.import(regime, filename)
    Thread.current[:current_user] = User.system_account

    n = regime.permit_categories.count
    destroy_bom = true
    CSV.foreach(filename, headers: false) do |row|
      code = row[0]
      desc = row[1]
      if destroy_bom
        code = TcmUtils.strip_bom(code)
        destroy_bom = false
      end
      n += 1
      regime.permit_categories.find_or_create_by!(code: code) do |cat|
        cat.description = desc
        cat.status = "active"
      end
    end
  end
end
