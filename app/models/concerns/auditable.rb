module Auditable
  extend ActiveSupport::Concern

  included do
    after_update :audit_changes
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
end
