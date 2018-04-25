class AuditService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def log_create(entity)
    add_entry(:create, entity)
  end

  def log_modify(entity)
    data = extract_changes(entity)
    add_entry(:modify, entity, data) unless data[:modifications].empty?
  end

  def log_delete
    add_entry(:delete, entity)
  end

  private
  def add_entry(action, entity, payload = nil)
    entity.audit_logs.create!(user: user, action: action, payload: payload)
  end

  def extract_changes(entity)
    mods = {}
    entity.audit_attributes.each do |attr|
    # [ :category,
    #   :temporary_cessation,
    #   :charge_calculation,
    #   :tcm_charge,
    #   :variation ].each do |attr|
      if entity.send("saved_change_to_#{attr}?")
        mods[attr] = [entity.send("#{attr}_before_last_save"),
                      entity.send(attr)]
      end
    end
    {
      modifications: mods
    }
  end
end
