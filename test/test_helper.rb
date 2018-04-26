require 'simplecov'
SimpleCov.start

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'minitest/reporters'
Minitest::Reporters.use!

require 'mocha/mini_test'

# remove http auth which is only for heroku deployment
ENV['HEROKU'] = nil

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def set_audit_user(user = nil)
    Thread.current[:current_user] = user || users(:billing_admin)
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers, ActiveJob::TestHelper
end
