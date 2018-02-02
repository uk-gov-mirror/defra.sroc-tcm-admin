require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:billing_admin)
    sign_in users(:system_admin)
  end

  test "should get index" do
    get users_url
    assert_response :success
  end

  test "should get show" do
    get user_url(@user)
    assert_response :success
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post users_url, params: new_user_params 
    end
    assert_redirected_to users_path
    assert_equal 'User account created', flash[:notice]
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    put user_url(@user), params: update_user_params
    assert_redirected_to users_path
    assert_equal 'User account updated', flash[:notice]
  end

  def new_user_params
    {
      user: {
        email: "ted@example.com",
        first_name: "Ted",
        last_name: "Test",
        enabled: "1",
        regime_users_attributes: {
          "0": {
            regime_id: regimes(:cfd).id,
            enabled: "1"
          }
        }
      }
    }
  end

  def update_user_params
    {
      user: {
        id: @user.id,
        first_name: "Fred"
      }
    }
  end
end
