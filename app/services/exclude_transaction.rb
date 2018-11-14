# frozen_string_literal: true

class ExcludeTransaction < ServiceObject
  attr_reader :transaction

  def initialize(params = {})
    @transaction = params.fetch(:transaction)
    @reason = params.fetch(:reason)
    @user = params.fetch(:user)
  end

  def call
    if @transaction.updateable?
      @result = @transaction.update_attributes(excluded: true,
                                               excluded_reason: @reason,
                                               charge_calculation: nil,
                                               tcm_charge: nil)
    else
      @result = false
    end
    self
  end
end
