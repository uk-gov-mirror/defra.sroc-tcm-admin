module TransactionCharge
  def extract_correct_charge(transaction)
    if transaction.charge_calculation
      amt = (transaction.charge_calculation["calculation"]["chargeValue"] * 100).round
      amt = -amt if transaction.line_amount.negative?
      amt
    end
  end
end
