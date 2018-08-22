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
    # @header.regime.permit_categories.create!(code: '2.4.5',
    #                                          description: 'test',
    #                                          status: 'active')
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
    transaction = @header.transaction_details.find_by(reference_3: 'AAAA0001')
    history = generate_historic_pas
    matched = history.first
    @processor.set_category(transaction, matched, :green, 'Level 99')
    assert_equal matched.category, transaction.reload.category
    sc = transaction.suggested_category
    assert_equal 'Assigned matching category', sc.logic
    assert_equal 'Level 99', sc.suggestion_stage
    assert sc.green?
  end

  def test_set_category_sets_matched_transaction
    history = generate_historic_pas
    matched = history.first
    transaction = @header.transaction_details.find_by(reference_3: 'AAAA0001')
    @processor.set_category(transaction, matched, :amber, 'Level')
    assert_equal matched.category, transaction.reload.category
    sc = transaction.suggested_category
    assert_equal matched, sc.matched_transaction, 'Matched transaction incorrect'
    assert_equal 'Assigned matching category', sc.logic
    assert sc.amber?, 'Confidence not AMBER'
  end

  def test_set_category_sets_charge_info
    transaction = @header.transaction_details.find_by(reference_3: 'AAAA0001')
    history = generate_historic_pas
    matched = history.first
    @processor.set_category(transaction, matched, :green, 'Level')
    assert_not_nil transaction.charge_calculation, 'Charge calculation not set'
    assert_not_nil transaction.tcm_charge, 'Charge not extracted'
  end

  def test_set_category_does_not_set_category_when_category_removed
    transaction = @header.transaction_details.
      find_by(reference_3: 'AAAA0001', customer_reference: 'A1234')
    history = generate_historic_pas
    matched = history.first
    p = PermitStorageService.new(@header.regime)
    p.update_or_create_new_version(matched.category, 'test', '1920', 'excluded')
    @processor.set_category(transaction, matched, :green, 'Level')
    assert_nil transaction.reload.category
    sc = transaction.suggested_category
    assert_equal 'Category not valid for financial year', sc.logic
    assert sc.red?, "Confidence not RED"
  end

  def test_set_category_does_not_set_category_if_calculation_error
    history = generate_historic_pas
    matched = history.first
    @calculator = build_mock_calculator_with_error
    @processor.stubs(:calculator).returns(@calculator)

    transaction = @header.transaction_details.
      find_by(reference_3: 'AAAA0001', customer_reference: 'A1234')
    @processor.set_category(transaction, matched, :green, 'Level')
    assert_nil transaction.reload.category
    sc = transaction.suggested_category
    assert_equal 'Error assigning charge', sc.logic
    assert sc.red?, "Confidence not RED"
  end

  def test_suggest_categories_processes_transactions_in_file
    history = generate_historic_pas
    @processor.suggest_categories

    [
      [ 'AAAA0001', 'A1234', '2.4.6', 'Assigned matching category' ],
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
      sc = t.suggested_category
      assert_equal td[3], sc.logic, "Failed logic #{td[0]}"
    end
  end

  def test_suggest_categories_does_not_consider_historic_credits
    historic = generate_historic_pas
    historic.last.update_attributes(line_amount: -1234)
    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_3: 'AAAA0001',
                                            customer_reference: 'A1234')
    assert_equal('2.4.5', t.category)
    sc = t.suggested_category
    assert_equal('Assigned matching category', sc.logic)
  end

  def test_suggest_categories_handles_multiple_matching_period_start
    historic = generate_historic_pas
    historic[1].update_attributes!(period_start: historic[0].period_start)
    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_3: 'AAAA0001',
                                            customer_reference: 'A1234')
    assert_nil t.category
    sc = t.suggested_category
    assert_equal('Multiple historic matches found', sc.logic)
  end

  def test_suggest_categories_generates_audit_records
    history = generate_historic_pas
    audit_before = AuditLog.count
    @processor.suggest_categories
    audit_after = AuditLog.count
    count = @header.transaction_details.where.not(category: nil).count
    assert count.positive?
    assert_equal count, (audit_after - audit_before)
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
      tt.category = nil
      tt.save!
    end
  end
end
