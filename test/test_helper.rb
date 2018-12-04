require 'simplecov'
SimpleCov.start

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'capybara/rails'
require 'capybara/minitest'
require 'capybara/minitest/spec'

require 'minitest/reporters'
Minitest::Reporters.use!

require 'selenium/webdriver'

require 'mocha/mini_test'

Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

# remove http auth which is only for heroku deployment
ENV['HEROKU'] = nil

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[ headless disable-gpu no-sandbox disable-dev-shm-usage ] }
  )
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities)
end

# Capybara.javascript_driver = :chrome
driver = ENV.fetch('TEST_DRIVER', :headless_chrome)
Capybara.javascript_driver = driver.to_sym

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
  include Capybara::DSL, Capybara::Minitest::Assertions

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('jQuery.active').zero?
    end
  end

  # call super whenever this is overridden in test classes
  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
