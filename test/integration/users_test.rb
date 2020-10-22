# frozen_string_literal: true

require "test_helper"

class UsersTest < ActionDispatch::IntegrationTest

  def setup
    Capybara.current_driver = Capybara.javascript_driver
    @user = users(:system_admin)
    sign_in @user
  end

  def test_can_filter_by_regime
    visit users_path

    Regime.all.each do |regime|
      page.select regime.title, from: "regime"
      tbl = page.find "div.tcm-table table"
      assert tbl.has_selector? "tbody>tr", count: regime.users.count
    end
  end

  def test_can_filter_by_role
    visit users_path

    User.roles.each_key do |r|
      txt = I18n.t(r, scope: "user.roles")
      page.select txt, from: "role"
      tbl = page.find "div.tcm-table table"
      assert tbl.has_selector? "tbody>tr", count: User.where(role: User.roles[r]).count
    end
  end
end
