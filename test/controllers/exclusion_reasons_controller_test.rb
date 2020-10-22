# frozen_string_literal: true

require "test_helper"

class ExclusionReasonsControllerTest < ActionDispatch::IntegrationTest
  def setup
    sign_in users(:system_admin)
    @regime = regimes(:cfd)
    @reasons = @regime.exclusion_reasons.order(:reason)
  end

  def test_it_should_get_index_for_system_admin
    get regime_exclusion_reasons_path(@regime)
    assert_response :success
    assert_equal @reasons, assigns(:reasons)
  end

  def test_it_should_get_new_for_system_admin
    get new_regime_exclusion_reason_path(@regime)
    assert_response :success
    assert_not_nil assigns(:reason)
  end

  def test_it_should_create_reason_for_system_admin
    params = { exclusion_reason: { reason: "Trod on false teeth" } }
    assert_difference "ExclusionReason.count" do
      post regime_exclusion_reasons_path(@regime), params: params
    end
    assert_redirected_to regime_exclusion_reasons_path(@regime)
  end

  def test_it_should_get_edit_for_system_admin
    get edit_regime_exclusion_reason_path(@regime, @reasons.first)
    assert_response :success
    assert_equal @reasons.first, assigns(:reason)
  end

  def test_it_should_update_reason_for_system_admin
    params = { exclusion_reason: { reason: "Slightly shrimpy smell" } }
    patch regime_exclusion_reason_path(@regime, @reasons.first), params: params
    assert_equal "Slightly shrimpy smell", @reasons.first.reload.reason
    assert_redirected_to regime_exclusion_reasons_path(@regime)
  end

  def test_it_should_delete_reason_for_system_admin
    assert_difference "ExclusionReason.count", -1 do
      delete regime_exclusion_reason_path(@regime, @reasons.first)
    end
    assert_redirected_to regime_exclusion_reasons_path(@regime)
  end

  def test_it_should_get_index_for_billing_admin
    sign_in users(:billing_admin)
    get regime_exclusion_reasons_path(@regime)
    assert_response :success
    assert_equal @reasons, assigns(:reasons)
  end

  def test_it_should_not_get_new_for_billing_admin
    sign_in users(:billing_admin)
    get new_regime_exclusion_reason_path(@regime)
    assert_redirected_to root_path
  end

  def test_it_should_not_get_new_for_read_only
    sign_in users(:cfd_read_only)
    get new_regime_exclusion_reason_path(@regime)
    assert_redirected_to root_path
  end

  def test_it_should_not_create_for_billing_admin
    sign_in users(:billing_admin)
    params = { exclusion_reason: { reason: "Trod on false teeth" } }
    assert_no_difference "ExclusionReason.count" do
      post regime_exclusion_reasons_path(@regime), params: params
    end
    assert_redirected_to root_path
  end

  def test_it_should_not_create_for_read_only
    sign_in users(:cfd_read_only)
    params = { exclusion_reason: { reason: "Trod on false teeth" } }
    assert_no_difference "ExclusionReason.count" do
      post regime_exclusion_reasons_path(@regime), params: params
    end
    assert_redirected_to root_path
  end

  def test_it_should_not_get_edit_for_billing_admin
    sign_in users(:billing_admin)
    get edit_regime_exclusion_reason_path(@regime, @reasons.first)
    assert_redirected_to root_path
  end

  def test_it_should_not_get_edit_for_read_only
    sign_in users(:cfd_read_only)
    get edit_regime_exclusion_reason_path(@regime, @reasons.first)
    assert_redirected_to root_path
  end

  def test_it_should_not_update_reason_for_billing_admin
    sign_in users(:billing_admin)
    params = { exclusion_reason: { reason: "Slightly shrimpy smell" } }
    patch regime_exclusion_reason_path(@regime, @reasons.first), params: params
    assert_not_equal "Slightly shrimpy smell", @reasons.first.reload.reason
    assert_redirected_to root_path
  end

  def test_it_should_not_update_reason_for_read_only
    sign_in users(:cfd_read_only)
    params = { exclusion_reason: { reason: "Slightly shrimpy smell" } }
    patch regime_exclusion_reason_path(@regime, @reasons.first), params: params
    assert_not_equal "Slightly shrimpy smell", @reasons.first.reload.reason
    assert_redirected_to root_path
  end

  def test_it_should_not_delete_reason_for_billing_admin
    sign_in users(:billing_admin)
    assert_no_difference "ExclusionReason.count" do
      delete regime_exclusion_reason_path(@regime, @reasons.first)
    end
    assert_redirected_to root_path
  end

  def test_it_should_not_delete_reason_for_read_only
    sign_in users(:cfd_read_only)
    assert_no_difference "ExclusionReason.count" do
      delete regime_exclusion_reason_path(@regime, @reasons.first)
    end
    assert_redirected_to root_path
  end
end
