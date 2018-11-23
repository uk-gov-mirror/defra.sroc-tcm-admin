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

  def test_it_should_use_history_export_for_csv
    csv = mock
    csv.expects(:export_history).returns("test")
    HistoryController.any_instance.stubs(:csv).returns(csv)

    get regime_history_index_url(@regime, format: :csv)
  end
end
