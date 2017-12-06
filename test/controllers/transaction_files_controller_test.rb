require 'test_helper.rb'

class TransactionFilesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @regimes = Regime.all #regimes(:cfd)
  end

  def test_it_should_get_index
    @regimes.each do |regime|
      get regime_transaction_files_url(regime)
      assert_response :success
    end
  end

  def test_create_should_redirect_to_transactions_to_be_billed
    @regimes.each do |regime|
      post regime_transaction_files_url(regime), params: { region: 'A' }
      assert_redirected_to regime_transactions_path(regime)
    end
  end
end
