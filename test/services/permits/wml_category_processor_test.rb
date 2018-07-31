require 'test_helper.rb'

class WmlCategoryProcessorTest < ActiveSupport::TestCase
  include ChargeCalculation, GenerateHistory
  def setup
    @header = transaction_headers(:wml_annual)
    fixup_transactions(@header)
 
    @user = User.system_account
    Thread.current[:current_user] = @user

    @processor = Permits::WmlCategoryProcessor.new(@header)
    @calculator = build_mock_calculator
    @processor.stubs(:calculator).returns(@calculator)
    @header.regime.permit_categories.create!(code: '2.15.3',
                                             description: 'test',
                                             status: 'active')
  end

  def test_fetch_unique_consents_returns_list_of_consent_references
    consents = @header.transaction_details.pluck(:reference_1).uniq.sort
    assert_equal consents, @processor.fetch_unique_consents
  end

  def test_only_invoices_in_file_returns_true_when_only_invoices_in_file_for_permit
    assert @processor.only_invoices_in_file? '0123456'
  end

  def test_only_invoices_in_file_returns_false_when_credits_in_file_for_permit
   refute @processor.only_invoices_in_file? '0123451'
  end

  def test_find_latest_historic_transaction_returns_nil_when_no_matches_found
    assert_nil @processor.find_latest_historic_transaction(['0123456', '1'])
  end

  def test_find_historic_transaction_returns_newest_matching_transaction
    # newest == newest period_end date
    historic = generate_historic_wml
    assert_equal historic[1], @processor.find_latest_historic_transaction(['0123456', '1'])
  end

  def test_set_category_sets_category
    transaction = @header.transaction_details.
      find_by(reference_1: '0123456')
    @processor.set_category(transaction, '2.15.2')
    assert_equal '2.15.2', transaction.reload.category
    assert_equal 'Assigned matching category', transaction.category_logic
  end

  def test_set_category_sets_charge_info
    transaction = @header.transaction_details.
      find_by(reference_1: '0123456')
    @processor.set_category(transaction, '2.15.2')
    assert_not_nil transaction.charge_calculation
    assert_not_nil transaction.tcm_charge
  end

  def test_set_category_does_not_set_category_when_category_removed
    transaction = @header.transaction_details.
      find_by(reference_1: '0123456')
    @processor.set_category(transaction, '2.3.9')
    assert_nil transaction.reload.category
    assert_equal 'Category not valid for financial year',
      transaction.category_logic
  end

  def test_set_category_does_not_set_category_if_calculation_error
    @calculator = build_mock_calculator_with_error
    @processor.stubs(:calculator).returns(@calculator)

    transaction = @header.transaction_details.
      find_by(reference_1: '0123456')
    @processor.set_category(transaction, '2.15.2')
    assert_nil transaction.reload.category
    assert_equal 'Error assigning charge', transaction.category_logic
  end

  def test_suggest_categories_processes_transactions_in_file
    history = generate_historic_wml
    @processor.suggest_categories

    [
      [ '0123456', '1', '2.15.3', 'Assigned matching category' ],
      [ '0123457', '1', nil, 'No previous bill found' ],
      [ '0123458', '1', nil, 'No previous bill found' ],
      [ '0123459', '1', nil, 'No previous bill found' ],
      [ '0123450', '1', nil, 'No previous bill found' ],
      [ '0123450', '2', nil, 'No previous bill found' ],
      [ '0123451', '1', nil, 'Not part of an annual bill' ],
      [ '0123451', '2', nil, 'Not part of an annual bill' ]
    ].each do |td|
      t = @header.transaction_details.find_by(reference_1: td[0],
                                              reference_3: td[1])
      assert_not_nil t, "Didnt find #{td[0]},#{td[1]}"
      if td[2].nil?
        assert_nil t.category, "Failed category #{td[0]}"
      else
        assert_equal td[2], t.category, "Failed category #{td[0]}"
      end
      assert_equal td[3], t.category_logic, "Failed logic #{td[0]}"
    end
  end

  def test_suggest_categories_does_not_consider_historic_credits
    historic = generate_historic_wml
    historic.last.update_attributes(line_amount: -1234)
    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_1: '0123456', reference_3: '1')
    assert_equal('2.15.2', t.category)
    assert_equal('Assigned matching category', t.category_logic)
  end

  def test_suggest_categories_generates_audit_records
    history = generate_historic_wml
    count = @header.transaction_details.count
    assert_difference 'AuditLog.count', count do
      @processor.suggest_categories
    end
  end

  def fixup_transactions(header)
    t = transaction_details(:wml_annual)
    [
      ["0123456", "E1234", "1", 12345, "A1234"],
      ["0123457", "E1235", "1", 67890, "A3453"],
      ["0123458", "E1236", "1", 12233, "A9483"],
      ["0123459", "E1237", "1", 22991, "A33133"],
      ["0123450", "E1238", "1", 435564, "A938392"],
      ["0123450", "E1238", "2", 23665, "A938392"],
      ["0123451", "E1239", "1", 124322, "A993022"],
      ["0123451", "E1239", "2", -123991, "A993022"]
    ].each_with_index do |ref, i|
      tt = t.dup
      tt.sequence_number = 2 + i
      tt.reference_1 = ref[0]
      tt.reference_2 = ref[1]
      tt.reference_3 = ref[2]
      tt.line_amount = ref[3]
      tt.customer_reference = ref[4]
      tt.transaction_header_id = header.id
      tt.period_start = '1-APR-2020'
      tt.period_end = '31-MAR-2021'
      tt.tcm_financial_year = '2021'
      tt.save!
    end
  end
end
