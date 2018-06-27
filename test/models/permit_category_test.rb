require 'test_helper'

class PermitCategoryTest < ActiveSupport::TestCase
  def setup
    @permit_category = permit_categories(:cfd)
  end

  def test_valid_permit_category
    assert @permit_category.valid?, "Unexpected errors present #{@permit_category.errors.inspect}"
  end

  def test_invalid_without_code
    @permit_category.code = nil
    assert @permit_category.invalid?
    assert_not_nil @permit_category.errors[:code]
  end

  def test_invalid_without_description_when_active
    @permit_category.status = 'active'
    @permit_category.description = nil
    assert @permit_category.invalid?
    assert_not_nil @permit_category.errors[:description]
  end

  def test_valid_without_description_when_excluded
    @permit_category.status = 'excluded'
    @permit_category.description = nil
    assert @permit_category.valid?
  end

  def test_invalid_without_valid_from
    @permit_category.valid_from = nil
    assert @permit_category.invalid?
    assert_not_nil @permit_category.errors[:valid_from]
  end

  def test_status_has_valid_state
    @permit_category.status = nil
    assert @permit_category.invalid?
    assert_not_nil @permit_category.errors[:status]

    @permit_category.status = 'bananas'
    assert @permit_category.invalid?
    assert_not_nil @permit_category.errors[:status]

    %w[active excluded].each do |state|
      @permit_category.status = state
      assert @permit_category.valid?
    end
  end

  def test_regime_code_and_valid_from_are_unique_scope
    p2 = @permit_category.dup
    assert p2.invalid?
    assert_not_nil p2.errors[:code]

    p2.valid_from = "1920"
    assert p2.valid?

    p2.valid_from = @permit_category.valid_from
    p2.code = p2.code + "1"
    assert p2.valid?

    p2.code = @permit_category.code
    p2.regime_id = regimes(:pas).id

    assert p2.valid?
  end

  def test_valid_from_is_4_digit_financial_year
    %w[ 12345 ABCD 1822 3311 ].each do |invalid_val|
      @permit_category.valid_from = invalid_val
      assert @permit_category.invalid?
      assert_not_nil @permit_category.errors[:valid_from]
    end 

    @permit_category.valid_from = "2122"
    assert @permit_category.valid?
  end

  def test_valid_to_is_4_digit_financial_year_or_nil
    %w[ 11223344 WXYZ 2224 3311 ].each do |invalid_val|
      @permit_category.valid_to = invalid_val
      assert @permit_category.invalid?
      assert_not_nil @permit_category.errors[:valid_to]
    end 

    @permit_category.valid_to = "2425"
    assert @permit_category.valid?

    @permit_category.valid_to = nil
    assert @permit_category.valid?
  end

  def test_valid_from_earlier_than_valid_to
    @permit_category.valid_to = "1718"
    assert @permit_category.invalid?
    assert_not_nil @permit_category.errors[:valid_from]
  end
end
