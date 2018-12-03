require 'test_helper'

class TransactionModeSelectionTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    @retro_text = "Pre-April 2018 Transactions to be billed"
    @wml_options = [ "Transactions to be billed",
                     "Transaction History",
                     "Excluded Transactions" ]
    @all_options = [ "Transactions to be billed",
                     "Transaction History",
                     @retro_text,
                     "Excluded Transactions" ]
  end

  def test_transaction_main_menu_has_no_retrospective_option_for_waste
    setup_wml
    visit regime_transactions_path(@regime)
    assert page.has_no_selector? "nav.main-menu a.dropdown-item",
      text: @retro_text
  end

  def test_transaction_main_menu_has_retrospective_option_for_installations
    setup_pas
    visit regime_transactions_path(@regime)
    assert page.has_selector? "nav.main-menu a.dropdown-item",
      text: @retro_text
  end

  def test_transaction_main_menu_has_retrospective_option_for_water_quality
    setup_cfd
    visit regime_transactions_path(@regime)
    assert page.has_selector? "nav.main-menu a.dropdown-item",
      text: @retro_text
  end

  def test_view_selector_has_no_retrospective_option_for_waste
    setup_wml
    [ regime_transactions_path(@regime),
      regime_history_index_path(@regime),
      regime_exclusions_path(@regime) ].each do |path|
        visit path
        assert page.has_select? "mode", options: @wml_options
      end
  end

  def test_view_selector_has_retrospective_option_for_installations
    setup_pas
    [ regime_transactions_path(@regime),
      regime_history_index_path(@regime),
      regime_retrospectives_path(@regime),
      regime_exclusions_path(@regime) ].each do |path|
        visit path
        assert page.has_select? "mode", options: @all_options
      end
  end

  def test_view_selector_has_retrospective_option_for_water_quality
    setup_cfd
    [ regime_transactions_path(@regime),
      regime_history_index_path(@regime),
      regime_retrospectives_path(@regime),
      regime_exclusions_path(@regime) ].each do |path|
        visit path
        assert page.has_select? "mode", options: @all_options
      end
  end
end
