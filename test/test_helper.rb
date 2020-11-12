# frozen_string_literal: true

# Require and run our simplecov initializer as the very first thing we do.
# This is as per its docs https://github.com/colszowka/simplecov#getting-started
require "./test/support/simplecov"

require File.expand_path("../config/environment", __dir__)
require "rails/test_help"

require "capybara/rails"
require "capybara/minitest"
require "capybara/minitest/spec"

require "selenium/webdriver"

require "mocha/minitest"

Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |f| require f }

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.args << "--headless"
    opts.args << "--disable-gpu" if Gem.win_platform?
    opts.args << "--no-sandbox"
    opts.args << "--disable-dev-shm-usage"
    opts.args << "--window-size=1600,1000"
    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.args << "--disable-site-isolation-trials"
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

driver = ENV.fetch("TEST_DRIVER", :headless_chrome)
Capybara.javascript_driver = driver.to_sym

Capybara.server = :puma, { Silent: true }

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def apply_audit_user(user = nil)
    Thread.current[:current_user] = user || users(:billing_admin)
  end
end

class ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Devise::Test::IntegrationHelpers
  include Capybara::Minitest::Assertions
  include Capybara::DSL

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script("jQuery.active").zero?
    end
  end

  # call super whenever this is overridden in test classes
  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
