# frozen_string_literal: true

class ApproveTransaction < ServiceObject
  attr_reader :transaction

  def initialize(params = {})
    super()
    @transaction = params.fetch(:transaction)
    @approver = params.fetch(:approver)
  end

  def call
    @result = if @transaction.ready_for_approval?
                @transaction.update(approved_for_billing: true,
                                    approver: @approver,
                                    approved_for_billing_at: Time.zone.now)
              else
                false
              end
    self
  end
end
