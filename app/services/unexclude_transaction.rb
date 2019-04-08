# frozen_string_literal: true

class UnexcludeTransaction < ServiceObject
  attr_reader :transaction

  def initialize(params = {})
    @transaction = params.fetch(:transaction)
    @user = params.fetch(:user)
  end

  def call
    if @transaction.excluded?
      @result = unexclude
    else
      @result = false
    end
    self
  end

  private
  def unexclude
    if @transaction.updateable?
      @transaction.excluded = false
      old_reason = @transaction.excluded_reason
      @transaction.excluded_reason = nil
      if @transaction.category.present?
        charge = generate_charge
        if charge.failure?
          # revert
          @transaction.excluded = true
          @transaction.excluded_reason = old_reason
        end
      end
      @transaction.save
    else
      # not updateable
      false
    end
  end

  def generate_charge
    charge = CalculateCharge.call(transaction: @transaction)
    @transaction.charge_calculation = charge.charge_calculation
    if charge.success?
      @transaction.tcm_charge = charge.amount
    else
      @transaction.tcm_charge = nil
    end
    charge
  end
end
