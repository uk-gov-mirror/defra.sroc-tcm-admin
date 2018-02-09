class SystemConfig < ApplicationRecord
  def self.config
    first_or_create
  end
  
  def start_import
    SystemConfig.transaction do
      if importing?
        false
      else
        update_attributes(importing: true, import_started_at: Time.zone.now)
      end
    end
  end

  def stop_import
    SystemConfig.transaction do
      if importing?
        update_attributes(importing: false)
      else
        false
      end
    end
  end
end
