require 'test_helper.rb'

class TransactionSummaryControllerTest < ActionDispatch::IntegrationTest
  def setup
    @regime = regimes(:cfd)
    @transaction = transaction_details(:cfd)
    sign_in users(:billing_admin)
  end

  def test_index_should_return_406_if_not_json_request
    get regime_transaction_summary_index_url(@regime)
    assert_response :not_acceptable
  end

  def test_it_should_get_index_for_json
    get regime_transaction_summary_index_url(@regime, format: :json)
    assert_response :success
  end
end

