module ChargeCalculation
  def build_mock_calculator
    calculator = mock('calculator')
    calculator.stubs(:calculate_transaction_charge).returns(dummy_charge)
    calculator
  end

  def build_mock_calculator_with_error
    calculator = mock('calculator')
    calculator.stubs(:calculate_transaction_charge).returns(error_charge)
    calculator
  end

  def dummy_charge
    {
      "uuid" => "8ae80f67-3879-4dd0-b03b-8531f986740d0",
      "generatedAt" => 2.seconds.ago.iso8601,
      "calculation" => {
        "chargeValue" => 1994.62,
        "environmentFlag" => "TEST",
        "decisionPoints" => {
          "baselineCharge" => 8865,
          "percentageAdjustment" => 3989.25,
          "temporaryCessation" => 1994.625,
          "complianceAdjustment" => 1994.625,
          "chargeType" => nil
        },
        "messages" => nil
      }
    }
  end

  def error_charge
    {
      "calculation" => {
        "messages" => 'Error message'
      }
    }
  end
end
