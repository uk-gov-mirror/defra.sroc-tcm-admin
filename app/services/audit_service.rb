class AuditService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def log_create(entity)
    add_entry(:create, entity)
  end

  def log_modify(entity)
    add_entry(:modify, entity, extract_changes(entity))
  end

  def log_delete
    add_entry(:delete, entity)
  end

  private
  def add_entry(action, entity, payload = {})
    entity.audit_logs.create!(user: user, action: action, payload: payload)
  end

  def extract_changes(entity)
    # attrs = entity.changed_attributes
    # mods = {}
    # attrs.each do |k, v|
    #   mods[k] = [v, entity.send(k)]
    # end
    mods = {}
    %i[category temporary_cessation charge_calculation tcm_charge variation].each do |attr|
      if entity.send("saved_change_to_#{attr}?")
        mods[attr] = [entity.send("#{attr}_before_last_save"),
                      entity.send(attr)]
      end
    end
    # mods = entity.previous_changes
    {
      # modifications: entity.previous_changes
      modifications: mods
    }
  end
end
