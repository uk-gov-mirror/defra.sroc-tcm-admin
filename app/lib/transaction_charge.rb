# frozen_string_literal: true

module TransactionCharge
  include RegimeScope

  def self.extract_correct_charge(transaction)
    if transaction.charge_calculation &&
       transaction.charge_calculation["calculation"] &&
       transaction.charge_calculation["calculation"]["chargeValue"]
      amt = (transaction.charge_calculation["calculation"]["chargeValue"] * 100).round
      amt = -amt if transaction.line_amount.negative?
      amt
    end
  end

  def self.extract_calculation_error(transaction)
    if transaction.charge_calculation &&
       transaction.charge_calculation["calculation"] &&
       transaction.charge_calculation["calculation"]["messages"]
      msg = transaction.charge_calculation["calculation"]["messages"]
      if msg.respond_to? :join
        msg.join('\n')
      else
        msg
      end
    end
  end

  def self.invoke_charge_calculation(calculator, transaction)
    calculator.calculate_transaction_charge(transaction)
  end
end
