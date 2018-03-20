require 'test_helper.rb'

class TransactionFilesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:billing_admin)
    sign_in @user
    @regime = @user.regimes.first
  end

  def test_it_should_get_index
    get regime_transaction_files_url(@regime)
    assert_response :success
  end

  # def test_create_should_redirect_to_transactions_to_be_billed
    # @regimes.each do |regime|
    #   post regime_transaction_files_url(regime), params: { region: 'A' }
    #   assert_redirected_to regime_transactions_path(regime)
    # end
  # end
end
