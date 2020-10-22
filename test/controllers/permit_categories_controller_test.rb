# frozen_string_literal: true

require "test_helper"

class PermitCategoriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @regime = regimes(:cfd)
    @permit_category = permit_categories(:cfd_a)
    sign_in users(:system_admin)
  end

  def test_it_should_get_index
    get regime_permit_categories_url(@regime)
    assert_response :success
    assert_nil assigns(:permit_categories)
  end

  def test_it_should_get_index_for_json
    get regime_permit_categories_url(@regime, format: :json)
    assert_response :success
    payload = assigns(:permit_categories)
    assert_not_nil payload
    assert_includes payload[:permit_categories], @permit_category
  end
end
