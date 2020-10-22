# frozen_string_literal: true

require "test_helper"

module Query
  class UsersTest < ActiveSupport::TestCase
    def test_returns_all_users
      count = User.all.count

      assert count.positive?, "No users"

      users = Users.call
      assert_equal count, users.count, "Different user counts"
    end
  end

  def test_filter_by_role
    User.roles.each_value do |n|
      count = User.where(role: n).count

      users = Users.call(role: n.to_s)
      assert_equal count, users.count, "Different user counts"

      users.each do |u|
        assert User.roles[u.role] == n, "Wrong role for user"
      end
    end
  end

  def test_filter_by_regime
    Regime.all.each do |regime|
      rus = regime.users

      users = Users.call(regime: regime.to_param)
      assert_equal rus.count, users.count, "Different user counts"

      users.each do |u|
        assert_includes rus, u, "User #{u.email} not in regime"
      end
    end
  end
end
