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

  # def test_it_should_show_transaction
  #   get regime_transaction_url(@regime, @transaction)
  #   assert_response :success
  #   assert_equal assigns(:transaction), @transaction
  # end
end
