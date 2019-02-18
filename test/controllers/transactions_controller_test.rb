require 'test_helper.rb'

class TransactionControllerTest < ActionDispatch::IntegrationTest
  include RegimeSetup, ChargeCalculation

  def setup
    # @regime = FactoryBot.create(:cfd)
    # @regime = regimes(:cfd)
    # @transaction = transaction_details(:cfd)
    # @user = users(:billing_admin)
    # sign_in users(:billing_admin)
    # Thread.current[:current_user] = @user
  end

  def test_it_should_get_index
    setup_cfd
    get regime_transactions_url(@regime)
    assert_response :success
  end
  
  def test_it_should_get_index_for_csv
    setup_cfd
    get regime_transactions_path(@regime, format: :csv)
    assert_response :success
  end

  def test_it_should_update_category
    setup_cfd
    stub_calculator
    @transaction = transaction_details(:cfd)
    refute @transaction.approved_for_billing
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { category: '2.3.5' }}
    assert_redirected_to regime_transaction_path(@regime, @transaction)
    assert_equal '2.3.5', @transaction.reload.category
    assert_not_nil @transaction.charge_calculation
    assert @transaction.approved_for_billing
  end

  def test_it_should_update_temporary_cessation
    setup_cfd
    stub_calculator
    @transaction = transaction_details(:cfd)
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { temporary_cessation: 'true' }}
    assert_redirected_to regime_transaction_path(@regime, @transaction)
    assert_equal true, @transaction.reload.temporary_cessation
  end

  def test_it_should_update_approved_for_billing
    setup_cfd
    stub_calculator
    @transaction = transaction_details(:cfd)
    @transaction.category = '2.3.5'
    @transaction.charge_calculation = dummy_charge
    @transaction.tcm_charge = 1234
    @transaction.save!

    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { approved_for_billing: true }}
    assert_redirected_to regime_transaction_path(@regime, @transaction)
    assert @transaction.reload.approved_for_billing, "Not approved"
  end

  def test_it_should_exclude_transaction
    setup_cfd
    @transaction = transaction_details(:cfd)
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { excluded: 'true', excluded_reason: 'Computer says no' }}
    assert_redirected_to regime_transaction_path(@regime, @transaction)
    assert @transaction.reload.excluded
  end

  def test_it_should_reinstate_transaction
    setup_cfd
    @transaction = transaction_details(:cfd)
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { excluded: 'false' }}
    assert_redirected_to regime_transaction_path(@regime, @transaction)
    refute @transaction.reload.excluded
  end

  def test_it_should_return_an_error_if_update_category_fails
    setup_cfd
    stub_calculator_error
    @transaction = transaction_details(:cfd)
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { category: 'Windy' }}
    assert_redirected_to regime_transaction_path(@regime, @transaction)
    assert_nil @transaction.reload.category
    assert_not_nil @transaction.charge_calculation['calculation']['messages']
  end

  def test_it_should_show_transaction
    setup_cfd
    @transaction = transaction_details(:cfd)
    get regime_transaction_url(@regime, @transaction)
    assert_response :success
    assert_equal assigns(:transaction), @transaction
  end

  def test_read_only_cannot_export_data
    setup_cfd_read_only
    get regime_transactions_url(@regime, format: :csv)
    assert_redirected_to root_path
  end

  def test_read_only_cannot_update_category
    setup_cfd_read_only
    stub_calculator
    @transaction = transaction_details(:cfd)
    category = @transaction.category
    assert_not_equal '2.3.5', category, "Category already set"
    refute @transaction.approved_for_billing
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { category: '2.3.5' }}
    assert_redirected_to root_path
    assert_not_equal '2.3.5', @transaction.reload.category
    assert_nil @transaction.charge_calculation
    refute @transaction.approved_for_billing
  end

  def test_read_only_cannot_update_temporary_cessation
    setup_cfd_read_only
    stub_calculator
    @transaction = transaction_details(:cfd)
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { temporary_cessation: 'true' }}
    assert_redirected_to root_path
    assert_equal false, @transaction.reload.temporary_cessation
  end

  def test_read_only_cannot_update_approved_for_billing
    setup_cfd_read_only
    stub_calculator
    Thread.current[:current_user] = users(:billing_admin)
    @transaction = transaction_details(:cfd)
    @transaction.category = '2.3.5'
    @transaction.charge_calculation = dummy_charge
    @transaction.tcm_charge = 1234
    @transaction.save!
    Thread.current[:current_user] = @user

    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { approved_for_billing: true }}
    assert_redirected_to root_path
    refute @transaction.reload.approved_for_billing, "Been approved"
  end

  def test_read_only_cannot_exclude_transaction
    setup_cfd_read_only
    @transaction = transaction_details(:cfd)
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { excluded: 'true', excluded_reason: 'Computer says no' }}
    assert_redirected_to root_path
    refute @transaction.reload.excluded
  end

  def test_read_only_cannot_reinstate_transaction
    setup_cfd_read_only
    @transaction = transaction_details(:cfd_excluded_invoice_1)
    # make only flagged for exclusion
    @transaction.update_attributes(status: 'unbilled')
    assert @transaction.excluded
    put regime_transaction_url(@regime, @transaction),
      params: { transaction_detail: { excluded: 'false' }}
    assert_redirected_to root_path
    assert @transaction.reload.excluded
  end

  def stub_calculator
    calculator = build_mock_calculator
    TransactionsController.any_instance.stubs(:calculator).returns(calculator)
  end

  def stub_calculator_error
    calculator = build_mock_calculator_with_error
    TransactionsController.any_instance.stubs(:calculator).returns(calculator)
  end
end
