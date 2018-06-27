class PermitCategory < ApplicationRecord
  belongs_to :regime

  validate :valid_from_is_financial_year
  validate :valid_to_is_financial_year_or_nil
  validate :valid_from_and_valid_to_is_valid_range
  validates :code, presence: true, uniqueness: { scope: [:regime_id, :valid_from] }
  validates :description, presence: true, unless: :excluded?
  validates :status, inclusion: { in: %w[active excluded],
    message: "%{value} is not a valid state" }

  scope :active, -> { where(status: 'active') }

  def self.by_financial_year(fy)
    t = arel_table
    where(t[:valid_from].lteq(fy)).where(t[:valid_to].eq(nil).or(t[:valid_to].gt(fy)))
  end

  def self.search(q)
    m = "%#{q}%"
    where(arel_table[:code].matches(m).
          or(arel_table[:description].matches(m)))
  end

  def active?
    status == 'active'
  end

  def excluded?
    status == 'excluded'
  end

  private

  def valid_from_is_financial_year
    validate_financial_year(:valid_from)
  end

  def valid_to_is_financial_year_or_nil
    validate_financial_year(:valid_to) unless valid_to.nil?
  end

  def validate_financial_year(attr)
    fy = send(attr)
    if fy.blank?
      errors.add(attr, "cannot be blank")
    else
      m = /\A(\d\d)(\d\d)\z/.match(fy)
      err = m.nil?
      err = (m[2].to_i != m[1].to_i + 1) unless err
      errors.add(attr, "is not a valid 4 character financial year value") if err
    end
  end

  def valid_from_and_valid_to_is_valid_range
    return if valid_to.nil?

    if valid_from >= valid_to
      errors.add(:valid_from, "Valid from must be earlier than valid to")
    end
  end
end
