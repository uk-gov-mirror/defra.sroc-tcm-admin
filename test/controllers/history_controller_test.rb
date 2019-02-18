require 'test_helper.rb'

class HistoryControllerTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def test_it_should_get_index
    setup_cfd
    get regime_history_index_url(@regime)
    assert_response :success
  end

  def test_it_should_get_index_for_csv
    setup_cfd
    get regime_history_index_url(@regime, format: :csv)
    assert_response :success
  end

  def test_read_only_cannot_export_data
    setup_cfd_read_only
    get regime_history_index_url(@regime, format: :csv)
    assert_redirected_to root_path
  end

end
