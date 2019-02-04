require 'test_helper.rb'

class RetrospectivesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @regime = regimes(:cfd)
    sign_in users(:billing_admin)
  end

  def test_it_should_get_index
    get regime_retrospectives_path(@regime)
    assert_response :success
  end

  def test_it_should_redirect_to_transactions_index_for_waste
    @regime = regimes(:wml)
    sign_in users(:wml_billing_admin)
    get regime_retrospectives_path(@regime)
    assert_redirected_to regime_transactions_path(@regime)
  end

  def test_it_should_get_index_for_csv
    get regime_retrospectives_path(@regime, format: :csv)
    assert_response :success
  end

  def test_it_should_use_export_for_csv
    csv = mock
    csv.expects(:full_export).returns("test")
    RetrospectivesController.any_instance.stubs(:csv).returns(csv)

    get regime_retrospectives_path(@regime, format: :csv)
  end
end
