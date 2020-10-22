# frozen_string_literal: true

class UnexcludeTransaction < ServiceObject
  attr_reader :transaction

  def initialize(params = {})
    super()
    @transaction = params.fetch(:transaction)
    @user = params.fetch(:user)
  end

  def call
    @result = if @transaction.excluded?
                unexclude
              else
                false
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
    @transaction.tcm_charge = (charge.amount if charge.success?)
    charge
  end
end
