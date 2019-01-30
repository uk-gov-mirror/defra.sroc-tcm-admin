require 'test_helper'

class ReadOnlyTransactionDetailsTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    # Capybara.current_driver = Capybara.javascript_driver
  end

  def test_exclude_button_not_available
    setup_pas_read_only
    t = @regime.transaction_details.unbilled.last
    visit regime_transaction_path(@regime, t)
    assert page.has_no_button?("Exclude from Billing"), "Exclude button found"
  end
end
