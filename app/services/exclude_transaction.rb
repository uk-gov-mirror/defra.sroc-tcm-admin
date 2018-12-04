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
      old_user = Thread.current[:current_user]
      Thread.current[:current_user] = @user
      @result = @transaction.update_attributes(excluded: true,
                                               excluded_reason: @reason,
                                               charge_calculation: nil,
                                               tcm_charge: nil)

      Thread.current[:current_user] = old_user
    else
      @result = false
    end
    self
  end
end
