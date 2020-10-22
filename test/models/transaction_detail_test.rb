# frozen_string_literal: true

require "test_helper"

class TransactionDetailTest < ActiveSupport::TestCase
  def setup
    @transaction = TransactionDetail.new(transaction_details(:cfd).attributes)
  end

  def test_valid_transaction_detail
    assert @transaction.valid?, "Unexpected errors present"
  end

  def test_invalid_without_sequence_number
    @transaction.sequence_number = nil
    assert @transaction.invalid?
    assert_not_nil @transaction.errors[:sequence_number]
  end

  def test_invalid_without_customer_reference
    @transaction.customer_reference = nil
    assert @transaction.invalid?
    assert_not_nil @transaction.errors[:customer_reference]
  end

  def test_invalid_without_line_amount
    @transaction.line_amount = nil
    assert @transaction.invalid?
    assert_not_nil @transaction.errors[:line_amount]
  end

  def test_invalid_without_unit_of_measure_price
    @transaction.unit_of_measure_price = nil
    assert @transaction.invalid?
    assert_not_nil @transaction.errors[:unit_of_measure_price]
  end

  def test_indicates__when_charge_calculation_present
    @transaction.charge_calculation = nil
    assert_not @transaction.charge_calculated?, "charge_calculated? != false"
    @transaction.charge_calculation = { some_value: 123_456 }
    assert @transaction.charge_calculated?, "charge_calculated? == false"
  end

  def test_indicates_if_charge_calculation_error_received
    calc = { calculation: { chargeAmount: 123.23 } }
    @transaction.charge_calculation = calc
    assert_not @transaction.charge_calculation_error?, "Unexpected error found"
    calc[:calculation][:messages] = "An error message"
    @transaction.charge_calculation = calc
    assert @transaction.charge_calculation_error?, "Error not found!"
  end

  def test_unbilled_scope_returns_unbilled_transactions
    transactions = TransactionDetail.where(status: "unbilled")
    assert_equal transactions, TransactionDetail.unbilled
  end

  def test_historic_scope_returns_historic_transactions
    transactions = TransactionDetail.where(status: "billed")
    assert_equal transactions, TransactionDetail.historic
  end

  def test_region_scope_returns_transactions_for_region
    TransactionDetail.all.distinct.pluck(:region).each do |region|
      transactions = TransactionDetail.where(region: region)
      assert_equal transactions, TransactionDetail.region(region)
    end
  end

  def test_search_matches_on_customer_reference
    check_search(:customer_reference)
  end

  def test_search_matches_on_reference_1
    check_search(:reference_1)
  end

  def test_search_matches_on_transaction_reference
    check_search(:transaction_reference)
  end

  def check_search(column)
    ref = @transaction.send(column)
    at = TransactionDetail.arel_table

    result = TransactionDetail.where(at[column].matches(ref))
    assert_equal result.to_a, TransactionDetail.search(ref).to_a
  end
end
