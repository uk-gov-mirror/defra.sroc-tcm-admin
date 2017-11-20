require 'test_helper'

class TransactionHeaderTest < ActiveSupport::TestCase
  def setup
    @regime = regimes(:cfd)
    @header = TransactionHeader.new(regime_id: @regime.id,
                                    feeder_source_code: 'CFD',
                                    region: 'A',
                                    file_type_flag: 'I',
                                    file_sequence_number: 1,
                                    generated_at: Time.zone.now)
  end

  def test_valid_transaction_header
    assert @header.valid?, "Unexpected errors present"
  end

  def test_invalid_without_feeder_source_code
    @header.feeder_source_code = nil
    assert @header.invalid?
    assert_not_nil @header.errors[:feeder_source_code]
  end

  def test_invalid_with_invalid_feeder_source_code
    @header.feeder_source_code = 'bananas'
    assert @header.invalid?
    assert_not_nil @header.errors[:feeder_source_code]
  end

  def test_valid_when_a_valid_feeder_source_code_selected
    %w[ PAS CFD WML ].each do |fsc|
      @header.feeder_source_code = fsc
      assert @header.valid?, "Header invalid with feeder_source_code #{fsc}!"
    end
  end

  def test_invalid_without_region
    @header.region = nil
    assert @header.invalid?
    assert_not_nil @header.errors[:region]
  end

  def test_invalid_without_file_type_flag
    @header.file_type_flag = nil
    assert @header.invalid?
    assert_not_nil @header.errors[:file_type_flag]
  end

  def test_invalid_with_invalid_file_type_flag
    @header.file_type_flag = 'X'
    assert @header.invalid?
    assert_not_nil @header.errors[:file_type_flag]
  end

  def test_valid_when_a_valid_file_type_flag_selected
    %w[ C I ].each do |ftf|
      @header.file_type_flag = ftf
      assert @header.valid?, "Header invalid with file_type_flag #{ftf}!"
    end
  end

  def test_invalid_without_file_sequence_number
    @header.file_sequence_number = nil
    assert @header.invalid?
    assert_not_nil @header.errors[:file_sequence_number]
  end

  def test_invalid_without_generated_at
    @header.generated_at = nil
    assert @header.invalid?
    assert_not_nil @header.errors[:generated_at]
  end

  def test_generates_the_file_reference
    # expecting CFDAI00001
    ref = [ @header.feeder_source_code,
            @header.region,
            @header.file_type_flag,
            "%05d" % @header.file_sequence_number].join
    assert_equal ref, @header.file_reference
  end
end
