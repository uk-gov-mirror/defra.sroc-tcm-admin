require 'test_helper.rb'

class PermitCategoriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # @regime = FactoryBot.create(:cfd)
    @regime = regimes(:cfd)
    @permit_category = FactoryBot.create(:permit_category, regime: @regime)
  end

  def test_it_should_get_index
    get regime_permit_categories_url(@regime)
    assert_response :success
    assert_equal(assigns(:permit_categories), [ @permit_category ])
  end
end
