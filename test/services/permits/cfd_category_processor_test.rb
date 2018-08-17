require 'test_helper.rb'

class CfdCategoryProcessorTest < ActiveSupport::TestCase
  include ChargeCalculation, GenerateHistory
  def setup
    @header = transaction_headers(:cfd_annual)
 
    @user = User.system_account
    Thread.current[:current_user] = @user

    @processor = Permits::CfdCategoryProcessor.new(@header)
    @calculator = build_mock_calculator
    @processor.stubs(:calculator).returns(@calculator)
  end

  def test_fetch_unique_consents_returns_list_of_consent_references
    fixup_annual(@header)
    consents = @header.transaction_details.pluck(:reference_1).uniq.sort
    assert_equal consents, @processor.fetch_unique_consents
  end

  def test_only_invoices_in_file_returns_true_when_only_invoices_in_file_for_consent
    fixup_annual(@header)
    assert @processor.only_invoices_in_file?(reference_1: 'AAAA/1/1')
  end

  def test_only_invoices_in_file_returns_false_when_credits_in_file_for_consent
    fixup_annual(@header)
    refute @processor.only_invoices_in_file?(reference_1: 'AAAF/2/3')
  end

  def test_find_latest_historic_invoice_returns_nil_when_no_matches_found
    fixup_annual(@header)
    assert_nil @processor.find_latest_historic_invoice(reference_1: 'AAAB/1/1')
  end

  def test_find_latest_historic_invoice_returns_newest_matching_transaction
    fixup_annual(@header)
    # newest == newest period_end date
    historic = generate_historic_cfd
    arg = { reference_1: 'AAAA/1/1' }
    assert_equal historic.first, @processor.find_latest_historic_invoice(arg)
  end

  def test_set_category_sets_category
    fixup_annual(@header)
    transaction = @header.transaction_details.find_by(reference_1: 'AAAA/1/1')
    @processor.set_category(transaction, '2.3.4', :amber)
    assert_equal '2.3.4', transaction.reload.category
    assert_equal 'Assigned matching category', transaction.category_logic
    assert transaction.amber?
  end

  def test_set_category_sets_charge_info
    fixup_annual(@header)
    transaction = @header.transaction_details.find_by(reference_1: 'AAAA/1/1')
    @processor.set_category(transaction, '2.3.4', :green)
    assert_not_nil transaction.charge_calculation
    assert_not_nil transaction.tcm_charge
    assert transaction.green?
  end

  def test_set_category_does_not_set_category_when_category_removed
    fixup_annual(@header)
    transaction = @header.transaction_details.find_by(reference_1: 'AAAA/1/1')
    @processor.set_category(transaction, '2.3.9', :green)
    assert_nil transaction.reload.category
    assert_equal 'Category not valid for financial year', transaction.category_logic
    assert_nil transaction.category_confidence_level
  end

  def test_set_category_does_not_set_category_if_calculation_error
    fixup_annual(@header)
    @calculator = build_mock_calculator_with_error
    @processor.stubs(:calculator).returns(@calculator)

    transaction = @header.transaction_details.find_by(reference_1: 'AAAA/1/1')
    @processor.set_category(transaction, '2.3.4', :amber)
    assert_nil transaction.reload.category
    assert_equal 'Error assigning charge', transaction.category_logic
    assert_nil transaction.category_confidence_level
  end

  # Scenario 1 - Annual bill, no supplementary on permit since previous annual bill
  def test_suggest_categories_assigns_categories_from_last_annual_bill
    fixup_annual(@header)
    history = generate_historic_cfd
    @processor.suggest_categories
    history.each do |ht|
      t = @header.transaction_details.find_by(reference_1: ht.reference_1)
      assert_equal(ht.category, t.category)
      assert_equal(t.category_logic, 'Assigned matching category')
      assert t.green?
    end
  end

  # Scenario 2 & 4 - Annual bill, variation (category change) since previous AB
  def test_suggest_categories_assigns_categories_from_last_variation
    fixup_annual(@header)
    history = generate_historic_with_supplemental_cfd

    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_1: 'AAAA/2/1')
    assert_equal(history.last.category, t.category)
    assert_equal('Assigned matching category', t.category_logic)
    assert t.green?
  end

  # Scenario 3 - Annual bill, new permit billed for the first time
  def test_suggest_categories_does_not_populate_category_for_new_permit
    fixup_annual(@header)
    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_1: 'AAAB/1/1')
    assert_nil t.category
    assert_equal('No previous bill found', t.category_logic)
    assert_nil t.category_confidence_level
  end

  # Scenario 5 - Annual bill, variation (new discharge) since previous AB
  def test_suggest_categories_assigns_categories_from_last_variation_and_version
    fixup_annual(@header)
    history = generate_historic_with_supplemental_cfd
    history.last.update_attributes(category: '2.3.5')
    t = history.last.dup
    t.line_amount = 567123
    t.reference_1 = "AAAA/2/2"
    t.reference_3 = '2'
    t.category = '2.3.6'
    t.save!
    history << t
    @processor.suggest_categories
    history.last(2).each do |ht|
      t = @header.transaction_details.find_by(reference_1: ht.reference_1)
      assert_equal(ht.category, t.category)
      assert_equal('Assigned matching category', t.category_logic)
      assert t.green?
    end
  end

  # Scenario 8 - Supplementary bill, permit category change, last bill was annual
  def test_suggest_categories_assigns_category_to_supplemental
    fixup_supplemental(@header)
    history = generate_historic_cfd
    @processor.suggest_categories
    ht = history.first
    t = @header.transaction_details.credits.find_by(reference_1: 'AAAA/1/1')
    assert_equal(ht.category, t.category)
    assert_equal('Assigned matching category', t.category_logic)
    assert t.green?
    t = @header.transaction_details.invoices.find_by(reference_1: 'AAAA/1/1')
    assert_equal(ht.category, t.category)
    assert_equal('Assigned matching category', t.category_logic)
    assert t.green?
    t = @header.transaction_details.invoices.find_by(reference_1: 'AAAA/2/1')
    assert_equal(ht.category, t.category)
    assert_equal('Assigned matching category', t.category_logic)
    assert t.amber?
  end

  # def test_suggest_categories_processes_transactions_in_file
  #   history = generate_historic_cfd
  #   @processor.suggest_categories
  #
  #   [
  #     [ 'ANQA/1234/1/2', nil, 'No previous bill found' ],
  #     [ 'AAAA/1/1', '2.3.5', 'Assigned matching category' ],
  #     [ 'AAAB/1/1', nil, 'No previous bill found' ],
  #     [ 'AAAC/1/1', nil, 'No previous bill found' ],
  #     [ 'AAAD/1/1', nil, 'No previous bill found' ],
  #     [ 'AAAE/1/1', nil, 'No previous bill found' ],
  #     [ 'AAAE/1/2', nil, 'No previous bill found' ],
  #     [ 'AAAF/2/3', nil, 'Not part of an annual bill' ]
  #   ].each do |td|
  #     t = @header.transaction_details.invoices.find_by(reference_1: td[0])
  #     if td[1].nil?
  #       assert_nil t.category, "Failed category #{td[0]}"
  #     else
  #       assert_equal td[1], t.category, "Failed category #{td[0]}"
  #     end
  #     assert_equal td[2], t.category_logic, "Failed logic #{td[0]}"
  #   end
  # end
  #
  # def test_suggest_categories_does_not_consider_historic_credits
  #   historic = generate_historic_cfd
  #   historic.last.update_attributes(category: '2.3.6', line_amount: -1234)
  #   @processor.suggest_categories
  #   t = @header.transaction_details.find_by(reference_1: 'AAAA/1/1')
  #   assert_equal('2.3.4', t.category)
  #   assert_equal('Assigned matching category', t.category_logic)
  # end
  #
  def test_suggest_categories_generates_audit_records
    fixup_annual(@header)
    history = generate_historic_cfd
    count = @header.transaction_details.count
    assert_difference 'AuditLog.count', count do
      @processor.suggest_categories
    end
  end

  def fixup_annual(header)
    t = transaction_details(:cfd_annual)
    [
      ["AAAA", "1", "1", 12345, "A1234"],
      ["AAAA", "1", "2", 546789, "A1234"],
      ["AAAA", "2", "1", 334455, "A1234"],
      ["AAAA", "2", "2", 21311, "A1234"],
      ["AAAB", "1", "1", 67890, "A3453"],
      ["AAAC", "1", "1", 12233, "A9483"],
      ["AAAD", "1", "1", 22991, "A33133"],
      ["AAAE", "1", "1", 435564, "A938392"],
      ["AAAE", "1", "2", 23665, "A938392"],
      ["AAAF", "2", "3", 124322, "A993022"],
      ["AAAF", "2", "3", -123991, "A993022"]
    ].each_with_index do |ref, i|
      tt = t.dup
      tt.sequence_number = 2 + i
      tt.reference_1 = ref[0..2].join('/')
      tt.reference_2 = ref[1]
      tt.reference_3 = ref[2]
      tt.line_amount = ref[3]
      tt.customer_reference = ref[4]
      tt.transaction_header_id = header.id
      tt.period_start = '1-APR-2019'
      tt.period_end = '31-MAR-2020'
      tt.tcm_financial_year = '1920'
      tt.save!
    end
  end

  def fixup_supplemental(header)
    t = transaction_details(:cfd_annual)
    [
      ["AAAA", "1", "1", -12345, "A1234", '1-APR-2018', '31-MAR-2019'],
      ["AAAA", "1", "1", 6789, "A1234", '1-APR-2018', '30-JUN-2018'],
      ["AAAA", "2", "1", 334455, "A1234", '1-JUL-2018', '31-MAR-2019']
    ].each_with_index do |ref, i|
      tt = t.dup
      tt.sequence_number = 2 + i
      tt.reference_1 = ref[0..2].join('/')
      tt.reference_2 = ref[1]
      tt.reference_3 = ref[2]
      tt.line_amount = ref[3]
      tt.customer_reference = ref[4]
      tt.transaction_header_id = header.id
      tt.period_start = ref[5]
      tt.period_end = ref[6]
      tt.tcm_financial_year = '1819'
      tt.save!
    end
  end
end
