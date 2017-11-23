require 'test_helper.rb'

class TransactionControllerTest < ActionDispatch::IntegrationTest
  def setup
    # @regime = FactoryBot.create(:cfd)
    @regime = regimes(:cfd)
    @transaction = transaction_details(:cfd)
  end

  def test_it_should_get_index
    get regime_transactions_url(@regime)
    assert_response :success
  end
  
  def test_it_should_get_index_for_json
    get regime_transactions_url(@regime, format: :json)
    assert_response :success
  end

  def test_it_should_update_category_and_calculate_charge_for_json
    stub_calculator
    put regime_transaction_url(@regime, @transaction, format: :json),
      params: { transaction_detail: { category: '1.2.3' }}
    assert_response :success
    assert_equal @transaction.reload.category, '1.2.3'
    assert_not_nil @transaction.charge_calculation
  end

  def test_it_should_return_an_error_if_update_category_fails
    put regime_transaction_url(@regime, @transaction, format: :json),
      params: { transaction_detail: { windmill: 'Windy' }}
    assert_response :unprocessable_entity
    assert_nil @transaction.reload.category
    assert_nil @transaction.charge_calculation
  end

  # def test_it_should_show_transaction
  #   get regime_transaction_url(@regime, @transaction)
  #   assert_response :success
  #   assert_equal assigns(:transaction), @transaction
  # end
  def stub_calculator
    calculator = mock()
    calculator.expects(:calculate_transaction_charge).returns({ calculation: { chargeValue: 12345.67 }})
    TransactionsController.any_instance.stubs(:calculator).returns(calculator)
  end
end
