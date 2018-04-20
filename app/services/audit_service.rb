class AuditService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def create(entity)
    add_entry(:create, entity)
  end

  def modify
    add_entry(:modify, entity)
  end

  def delete
    add_entry(:delete, entity)
  end

  def add_entry(action, entity)
  end
end
