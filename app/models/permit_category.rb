# frozen_string_literal: true

class PermitCategory < ApplicationRecord
  include Auditable

  audit_events %i[create update]
  audit_attributes %i[code
                      description
                      valid_from
                      valid_to
                      status]
  belongs_to :regime

  validate :valid_from_is_financial_year
  validate :valid_to_is_financial_year_or_nil
  validate :valid_from_and_valid_to_is_valid_range
  validates :code, format: {
    with: /\A(\d{1,4}|\d{1,4}\.\d{1,4}|\d{1,4}\.\d{1,4}\.\d{1,4})\z/,
    message: "Code must be in dotted numeric format, with 1 to 3 segments between"\
      " 1 and 4 digits long. e.g. 6, 1.2, 9.34.1, 27.111.1234"
  }
  validates :code, presence: true, uniqueness: { scope: %i[regime_id valid_from] }
  validates :description, presence: true, unless: :excluded?
  validates :description, length: { maximum: 150 }
  validate :description_has_no_invalid_characters

  validates :status, inclusion: { in: %w[active excluded],
                                  message: "%{value} is not a valid state" }

  scope :active, -> { where(status: "active") }

  def self.by_financial_year(financial_year)
    t = arel_table
    where(t[:valid_from].lteq(financial_year)).where(t[:valid_to].eq(nil).or(t[:valid_to].gt(financial_year)))
  end

  def self.search(query)
    m = "%#{sanitize_sql_like(query)}%"
    where(arel_table[:code].matches(m).or(arel_table[:description].matches(m)))
  end

  def active?
    status == "active"
  end

  def excluded?
    status == "excluded"
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
      err ||= (m[2].to_i != m[1].to_i + 1)
      errors.add(attr, "is not a valid 4 character financial year value") if err
    end
  end

  def valid_from_and_valid_to_is_valid_range
    return if valid_to.nil?

    return unless valid_from >= valid_to

    errors.add(:valid_from, "Valid from must be earlier than valid to")
  end

  def description_has_no_invalid_characters
    return unless description.present?
    return unless description =~ /[?\^£\u2014\u2264\u2265]/

    errors.add(
      :description,
      "^Description contains characters that are not permitted. Please modify your description to remove them."
    )
  end
end
