require 'test_helper.rb'

class PasCategoryProcessorTest < ActiveSupport::TestCase
  include ChargeCalculation, GenerateHistory
  def setup
    @header = transaction_headers(:pas_annual)
    fixup_transactions(@header)
 
    @user = User.system_account
    Thread.current[:current_user] = @user

    @processor = Permits::PasCategoryProcessor.new(@header)
    @calculator = build_mock_calculator
    @processor.stubs(:calculator).returns(@calculator)
    @header.regime.permit_categories.create!(code: '2.4.5',
                                             description: 'test',
                                             status: 'active')
  end

  def test_fetch_unique_pas_permits_returns_list_of_permits
    permits = @header.transaction_details.
      group(:reference_3, :customer_reference).count
    assert_equal permits, @processor.fetch_unique_pas_permits
  end

  def test_only_invoices_in_file_returns_true_when_only_invoices_in_file_for_permit
    assert @processor.only_invoices_in_file?(reference_3: 'AAAA0001',
                                             customer_reference: 'A1234')
  end

  def test_only_invoices_in_file_returns_false_when_credits_in_file_for_permit
   refute @processor.only_invoices_in_file?(reference_3: 'AAAA0007',
                                            customer_reference: 'A1239')
  end

  def test_find_historic_transactions_returns_empty_collection_when_no_matches_found
    assert @processor.find_historic_transactions(
      reference_3: 'AAAA0001', customer_reference: 'A1234').empty?
  end

  def test_find_historic_transactions_returns_most_recent_transactions_if_possible
    # newest == newest period_end date
    historic = generate_historic_pas
    matches = @processor.find_historic_transactions(
      reference_3: 'AAAA0001', customer_reference: 'A1234')
    assert_equal 1, matches.count
    assert_equal historic[1], matches.first
  end

  def test_find_historic_transactions_returns_collection_matching_period_start
    historic = generate_historic_pas
    historic[1].update_attributes!(period_start: historic[0].period_start)
    matches = @processor.find_historic_transactions(
      reference_3: 'AAAA0001', customer_reference: 'A1234')
    assert_equal 2, matches.count
  end

  def test_set_category_sets_category
    transaction = @header.transaction_details.
      find_by(reference_3: 'AAAA0001')
    @processor.set_category(transaction, '2.4.4', :green)
    assert_equal '2.4.4', transaction.reload.category
    assert_equal 'Assigned matching category', transaction.category_logic
    assert transaction.green?
  end

  def test_set_category_sets_charge_info
    transaction = @header.transaction_details.
      find_by(reference_3: 'AAAA0001')
    @processor.set_category(transaction, '2.4.4', :green)
    assert_not_nil transaction.charge_calculation
    assert_not_nil transaction.tcm_charge
    assert transaction.green?
  end

  def test_set_category_does_not_set_category_when_category_removed
    transaction = @header.transaction_details.
      find_by(reference_3: 'AAAA0001', customer_reference: 'A1234')
    @processor.set_category(transaction, '2.3.9', :green)
    assert_nil transaction.reload.category
    assert_equal 'Category not valid for financial year', transaction.category_logic
    assert_nil transaction.category_confidence_level
  end

  def test_set_category_does_not_set_category_if_calculation_error
    @calculator = build_mock_calculator_with_error
    @processor.stubs(:calculator).returns(@calculator)

    transaction = @header.transaction_details.
      find_by(reference_3: 'AAAA0001', customer_reference: 'A1234')
    @processor.set_category(transaction, '2.4.4', :green)
    assert_nil transaction.reload.category
    assert_equal 'Error assigning charge', transaction.category_logic
    assert_nil transaction.category_confidence_level
  end

  def test_suggest_categories_processes_transactions_in_file
    history = generate_historic_pas
    @processor.suggest_categories

    [
      [ 'AAAA0001', 'A1234', '2.4.5', 'Assigned matching category' ],
      [ 'AAAA0002', 'A1235', nil, 'No previous bill found' ],
      [ 'AAAA0003', 'A1236', nil, 'No previous bill found' ],
      [ 'AAAA0004', 'A1237', nil, 'No previous bill found' ],
      [ 'AAAA0005', 'A1238', nil, 'No previous bill found' ],
      [ 'AAAA0006', 'A1238', nil, 'No previous bill found' ],
      [ 'AAAA0007', 'A1239', nil, 'Not part of an annual bill' ],
      [ 'AAAA0008', 'A1230', nil, 'Multiple matching permits in file found' ]
    ].each do |td|
      t = @header.transaction_details.find_by(reference_3: td[0],
                                              customer_reference: td[1])
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
    historic = generate_historic_pas
    historic.last.update_attributes(line_amount: -1234)
    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_3: 'AAAA0001',
                                            customer_reference: 'A1234')
    assert_equal('2.4.4', t.category)
    assert_equal('Assigned matching category', t.category_logic)
  end

  def test_suggest_categories_handles_multiple_matching_period_start
    historic = generate_historic_pas
    historic[1].update_attributes!(period_start: historic[0].period_start)
    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_3: 'AAAA0001',
                                            customer_reference: 'A1234')
    assert_nil t.category
    assert_equal('Multiple historic matches found', t.category_logic)
  end

  def test_suggest_categories_generates_audit_records
    history = generate_historic_pas
    count = @header.transaction_details.count
    assert_difference 'AuditLog.count', count do
      @processor.suggest_categories
    end
  end

  def fixup_transactions(header)
    t = transaction_details(:pas_annual)
    [
      ["AAAA0001", 12345, "A1234"],
      ["AAAA0002", 67890, "A1235"],
      ["AAAA0003", 12233, "A1236"],
      ["AAAA0004", 22991, "A1237"],
      ["AAAA0005", 43554, "A1238"],
      ["AAAA0006", 23665, "A1238"],
      ["AAAA0007", 124322, "A1239"],
      ["AAAA0007", -123991, "A1239"],
      ["AAAA0008", 34567, "A1230"],
      ["AAAA0008", 9854, "A1230"]
    ].each_with_index do |ref, i|
      tt = t.dup
      tt.sequence_number = 2 + i
      tt.reference_3 = ref[0]
      tt.line_amount = ref[1]
      tt.customer_reference = ref[2]
      tt.transaction_header_id = header.id
      tt.period_start = '1-APR-2020'
      tt.period_end = '31-MAR-2021'
      tt.tcm_financial_year = '2021'
      tt.save!
    end
  end
end
