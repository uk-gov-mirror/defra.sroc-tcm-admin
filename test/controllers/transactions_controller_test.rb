require 'test_helper.rb'

class TransactionControllerTest < ActionDispatch::IntegrationTest
  include ChargeCalculation

  def setup
    # @regime = FactoryBot.create(:cfd)
    @regime = regimes(:cfd)
    @transaction = transaction_details(:cfd)
    @user = users(:billing_admin)
    sign_in users(:billing_admin)
    Thread.current[:current_user] = @user
  end

  def test_it_should_get_index
    get regime_transactions_url(@regime)
    assert_response :success
  end
  
  def test_it_should_update_category
    stub_calculator
    @transaction = transaction_details(:cfd)
    refute @transaction.approved_for_billing
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { category: '2.3.5' }}
    assert_redirected_to edit_regime_transaction_path(@regime, @transaction)
    assert_equal '2.3.5', @transaction.reload.category
    assert_not_nil @transaction.charge_calculation
    assert @transaction.approved_for_billing
  end

  def test_it_should_update_temporary_cessation
    stub_calculator
    @transaction = transaction_details(:cfd)
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { temporary_cessation: 'true' }}
    assert_redirected_to edit_regime_transaction_path(@regime, @transaction)
    assert_equal true, @transaction.reload.temporary_cessation
  end

  def test_it_should_update_approved_for_billing
    stub_calculator
    @transaction = transaction_details(:cfd)
    @transaction.category = '2.3.5'
    @transaction.charge_calculation = dummy_charge
    @transaction.tcm_charge = 1234
    @transaction.save!

    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { approved_for_billing: true }}
    assert_redirected_to edit_regime_transaction_path(@regime, @transaction)
    assert @transaction.reload.approved_for_billing, "Not approved"
  end

  def test_it_should_return_an_error_if_update_category_fails
    stub_calculator_error
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { category: 'Windy' }}
    assert_redirected_to edit_regime_transaction_path(@regime, @transaction)
    assert_nil @transaction.reload.category
    assert_not_nil @transaction.charge_calculation['calculation']['messages']
  end

  def test_it_should_show_transaction
    get regime_transaction_url(@regime, @transaction)
    assert_response :success
    assert_equal assigns(:transaction), @transaction
  end

  def stub_calculator
    calculator = build_mock_calculator
    # calculator = mock()
    # calculator.expects(:calculate_transaction_charge).returns({ calculation: { chargeValue: 12345.67 }})
    TransactionsController.any_instance.stubs(:calculator).returns(calculator)
  end

  def stub_calculator_error
    calculator = build_mock_calculator_with_error
    # calculator = mock()
    # calculator.expects(:calculate_transaction_charge).returns({ calculation: { messages: 'Error message' }})
    TransactionsController.any_instance.stubs(:calculator).returns(calculator)
  end
end
