# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :user, inverse_of: :audit_logs
  belongs_to :auditable, polymorphic: true

  ACTIONS = %w[create modify delete].freeze

  validates :action, inclusion: { in: AuditLog::ACTIONS }
end
