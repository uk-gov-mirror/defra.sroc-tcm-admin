class AuditLog < ApplicationRecord
  belongs_to :user, inverse_of: :audit_logs
  belongs_to :auditable, polymorphic: true

  Actions = %w[ create modify delete ].freeze

  validates :action, inclusion: { in: AuditLog::Actions }
end
