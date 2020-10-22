# frozen_string_literal: true

module ChargeCalculation
  def build_mock_calculator
    CalculateCharge.any_instance.stubs(:calculate_charge).returns(true)
    CalculateCharge.any_instance.stubs(:charge_calculation).returns(dummy_charge)
  end

  def build_mock_calculator_with_error
    CalculateCharge.any_instance.stubs(:calculate_charge).returns(false)
    CalculateCharge.any_instance.stubs(:charge_calculation).returns(error_charge)
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
        "messages" => "Error message"
      }
    }
  end
end
