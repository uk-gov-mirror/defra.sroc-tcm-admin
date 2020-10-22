# frozen_string_literal: true

class UpdateCategory < ServiceObject
  attr_reader :transaction

  def initialize(params = {})
    super()
    @transaction = params.fetch(:transaction)
    @category = params.fetch(:category)
    @user = params.fetch(:user)
  end

  def call
    TransactionDetail.transaction do
      @result = update
    end
    self
  end

  private

  def update
    if @transaction.updateable?
      if @transaction.category != @category
        success = true
        old_category = @transaction.category
        if @category.blank?
          @transaction.category = nil
          clear_charge
          override_suggestion
        else
          @transaction.category = @category
          charge = generate_charge
          if charge.success?
            override_suggestion
            approve_transaction
          else
            # revert
            @transaction.category = old_category
            success = false
          end
        end
        @transaction.save!
        success
      else
        # no change
        true
      end
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

  def clear_charge
    @transaction.charge_calculation = nil
    @transaction.tcm_charge = nil
  end

  def override_suggestion
    return unless @transaction.suggested_category

    @transaction.suggested_category.update_attributes(overridden: true)
  end

  def approve_transaction
    ApproveTransaction.call(transaction: @transaction, approver: @user)
  end
end
