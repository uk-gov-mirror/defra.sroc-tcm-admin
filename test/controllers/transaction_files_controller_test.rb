require 'test_helper.rb'

class TransactionFilesControllerTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def test_it_should_get_index
    setup_cfd
    get regime_transaction_files_path(@regime)
    assert_response :success
  end

  def test_create_should_redirect_to_transactions_to_be_billed
    setup_cfd
    post regime_transaction_files_url(@regime), params: { region: 'A' }
    assert_redirected_to regime_transactions_path(@regime, page: 1)
  end

  def test_read_only_cannot_create
    setup_cfd_read_only
    post regime_transaction_files_url(@regime), params: { region: 'A' }
    assert_redirected_to root_path
  end
end
