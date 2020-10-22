# frozen_string_literal: true

class UnapproveTransaction < ServiceObject
  attr_reader :transaction

  def initialize(params = {})
    super()
    @transaction = params.fetch(:transaction)
    @approver = params.fetch(:approver)
  end

  def call
    @result = if @transaction.approved?
                @transaction.update_attributes(approved_for_billing: false,
                                               approver: @approver,
                                               approved_for_billing_at: Time.zone.now)
              else
                false
              end
    self
  end
end
