module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :auditable
    after_update :audit_changes

    class_attribute :auditable_attributes
  end

  def audit_attributes
    self.auditable_attributes || []
  end

  private

  def audit_changes
    auditor.log_modify(self)
  end

  def auditor
    @auditor ||= AuditService.new(current_user)
  end

  def current_user
    Thread.current[:current_user]
  end

  module ClassMethods
    def audit_attributes(attrs)
      self.auditable_attributes = attrs
    end
  end
end
