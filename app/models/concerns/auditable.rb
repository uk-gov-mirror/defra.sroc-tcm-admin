module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :auditable

    after_create :audit_create
    after_update :audit_changes

    class_attribute :auditable_events
    class_attribute :auditable_attributes
  end

  def audit_events
    self.auditable_events || []
  end

  def audit_attributes
    self.auditable_attributes || []
  end

  private

  def audit_create
    auditor.log_create(self) if audit_events.include? :create
  end

  def audit_changes
    auditor.log_modify(self) if audit_events.include? :update
  end

  def auditor
    @auditor ||= AuditService.new(current_user)
  end

  def current_user
    Thread.current[:current_user]
  end

  module ClassMethods
    def audit_events(events)
      self.auditable_events = Array.wrap(events)
    end

    def audit_attributes(attrs)
      self.auditable_attributes = Array.wrap(attrs)
    end
  end
end
