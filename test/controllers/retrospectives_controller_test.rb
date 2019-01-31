require 'test_helper.rb'

class RetrospectivesControllerTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def test_it_should_get_index
    setup_cfd
    get regime_retrospectives_path(@regime)
    assert_response :success
  end

  def test_it_should_redirect_to_transactions_index_for_waste
    setup_wml
    get regime_retrospectives_path(@regime)
    assert_redirected_to regime_transactions_path(@regime)
  end

  def test_it_should_get_index_for_csv
    setup_cfd
    get regime_retrospectives_path(@regime, format: :csv)
    assert_response :success
  end

  def test_read_only_cannot_export_data
    setup_cfd_read_only
    get regime_retrospectives_path(@regime, format: :csv)
    assert_redirected_to root_path
  end
end
