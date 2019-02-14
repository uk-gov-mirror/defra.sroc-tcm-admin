require 'test_helper'

class ReadOnlyExportMenuTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    Capybara.current_driver = Capybara.javascript_driver
  end

  def test_admin_menu_not_available
    setup_pas_read_only_export
    visit regime_transactions_path(@regime)
    assert page.has_no_selector?("a#navbarAdminSelectorLink")
  end

  def test_transactions_menu_available
    setup_pas_read_only_export
    visit regime_transactions_path(@regime)
    assert page.has_selector?("a#navbarTransactionsSelectorLink")
  end

  def test_transactions_menu_has_correct_options
    setup_pas_read_only_export
    visit regime_transactions_path(@regime)
    page.click_link("Transactions")
    page.find("div.dropdown-menu") do |menu|
      assert menu.has_selector?("a.dropdown-item", count: 5)
      assert menu.has_link?("Transactions to be billed")
      assert menu.has_link?("Transaction History")
      assert menu.has_link?("Pre-April 2018 Transactions to be billed")
      assert menu.has_no_link?("Excluded Transactions")
      assert menu.has_link?("Transaction File History")
      assert menu.has_link?("Download Transaction Data")
    end
  end

  def test_annual_billing_menu_not_available
    setup_pas_read_only_export
    visit regime_transactions_path(@regime)
    assert page.has_no_selector?("a#navbarAnnualBillingSelectorLink")
  end
end
