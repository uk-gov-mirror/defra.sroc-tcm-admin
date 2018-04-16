require 'test_helper.rb'

class TransactionFilesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:billing_admin)
    sign_in @user
    @regime = @user.regimes.first
  end

  def test_create_should_redirect_to_transactions_to_be_billed
    post regime_transaction_files_url(@regime), params: { region: 'A' }
    assert_redirected_to regime_transactions_path(@regime)
  end
end
