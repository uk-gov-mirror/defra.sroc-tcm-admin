module TransactionCharge
  include RegimeScope

  def extract_correct_charge(transaction)
    if transaction.charge_calculation
      amt = (transaction.charge_calculation["calculation"]["chargeValue"] * 100).round
      amt = -amt if transaction.line_amount.negative?
      amt
    end
  end

  def extract_calculation_error(transaction)
    if transaction.charge_calculation
      transaction.charge_calculation["calculation"]["messages"]
    end
  end

  def invoke_charge_calculation(transaction)
    # presenter is in RegimeScope module
    calculator.calculate_transaction_charge(presenter.new(transaction))
  end

  # We'll stub / mock this to prevent WS calls
  # :nocov:
  def calculator
    @calculator ||= CalculationService.new
  end
  # :nocov:
end
