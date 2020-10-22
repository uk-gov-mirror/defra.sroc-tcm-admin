# frozen_string_literal: true

class ExtractAuditDetail < ServiceObject
  attr_reader :transaction, :audit_details

  def initialize(params = {})
    super()
    @transaction = params.fetch(:transaction)
    @audit_details = nil
  end

  def call
    @audit_details = build_audit_detail
    @result = true
    self
  end

  private

  def build_audit_detail
    Enumerator.new do |y|
      d = ViewModels::AuditDetail.new
      d.action = "create"
      d.when = @transaction.created_at
      d.who = User.system_account
      d.new_value = @transaction.original_filename
      y << d

      @transaction.audit_logs.order(:created_at, :id).each do |l|
        case l.action
        when "modify"
          mods = l.payload.fetch("modifications", {})

          mods.each do |k, v|
            d = ViewModels::AuditDetail.new

            d.action = if k == "category" && l.user == User.system_account
                         "suggestion"
                       else
                         l.action
                       end

            d.when = l.created_at
            d.who = l.user

            d.attribute = k
            d.old_value = v[0]
            d.new_value = v[1]

            y << d
          end
        when "create"
          d = ViewModels::AuditDetail.new
          d.action = l.action
          d.when = l.created_at
          d.who = l.user

          y << d
        end
      end
      file = @transaction.transaction_file
      if file
        d = ViewModels::AuditDetail.new
        d.action = "export"
        d.when = file.generated_at
        d.who = file.user
        d.new_value = @transaction.generated_filename
        y << d
      end
    end
  end
end
