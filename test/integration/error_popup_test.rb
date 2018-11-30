require 'test_helper'

class ErrorPopupTest < ActionDispatch::IntegrationTest
  def setup
    Capybara.current_driver = Capybara.javascript_driver
    @regime = regimes(:cfd)
    @user = users(:billing_admin)
    @regions_only = @regime.transaction_headers.distinct.pluck(:region).sort
    @regions_with_all = [ 'All' ] + @regions_only
    @error_transaction = transaction_details(:cfd_unbilled_error_invoice)
    sign_in @user
  end

  def test_can_see_error_row_on_ttbb
    visit regime_transactions_path(@regime)

    page.assert_selector("tr.error", count: 1)
  end

  def test_can_see_error_message_when_clicked_on_ttbb
    visit regime_transactions_path(@regime)
    id = "#{@error_transaction.id}-error"
    msg = @error_transaction.charge_calculation['calculation']['messages']

    # click error details button
    page.click_button(id: id)
    # look at popover that appears
    page.find(".popover", visible: true) do |pop|
      pop.find(".popover-header").assert_text("Error")
      pop.find(".popover-body").assert_text(msg)
    end
  end
end
