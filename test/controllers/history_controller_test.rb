require 'test_helper.rb'

class HistoryControllerTest < ActionDispatch::IntegrationTest
  def setup
    @regime = regimes(:cfd)
    sign_in users(:billing_admin)
  end

  def test_it_should_get_index
    get regime_history_index_url(@regime)
    assert_response :success
  end

  def test_it_should_get_index_for_csv
    get regime_history_index_url(@regime, format: :csv)
    assert_response :success
  end
end
