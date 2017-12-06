class TransactionDetail < ApplicationRecord
  belongs_to :transaction_header, inverse_of: :transaction_details
  has_one :regime, through: :transaction_header

  validates :sequence_number, presence: true
  validates :customer_reference, presence: true
  validates :line_amount, presence: true
  validates :unit_of_measure_price, presence: true

  scope :unbilled, -> { where(status: 'unbilled') }
  scope :historic, -> { where(status: 'billed') }

  scope :with_charge_errors, -> { where("charge_calculation -> 'calculation' ->> 'messages' != null") }
  scope :credits, -> { where(arel_table[:line_amount].lt 0) }
  scope :invoices, -> { where(arel_table[:line_amount].gteq 0) }
  scope :region, ->(region) { joins(:transaction_header).merge(TransactionHeader.in_region(region)) }
  scope :without_charge, -> { where(charge_calculation: nil).or(TransactionDetail.with_charge_errors) }
  def self.search(q)
    m = "%#{q}%"
    where(arel_table[:customer_reference].matches(m).or(arel_table[:reference_1].matches(m)).or(arel_table[:transaction_reference].matches(m)))
  end

  def charge_calculated?
    charge_calculation.present?
  end

  def charge_calculation_error?
    charge_calculated? && charge_calculation["calculation"] && charge_calculation["calculation"]["messages"]
  end
end
