class TransactionDetail < ApplicationRecord
  belongs_to :transaction_header, inverse_of: :transaction_details
  has_one :regime, through: :transaction_header

  validates :sequence_number, presence: true
  validates :customer_reference, presence: true
  validates :line_amount, presence: true
  validates :unit_of_measure_price, presence: true

  scope :unbilled, -> { where(status: 'unbilled') }

  scope :credits, -> { where(arel_table[:line_amount].lt 0) }
  scope :invoices, -> { where(arel_table[:line_amount].gteq 0) }
  scope :region, ->(region) { joins(:transaction_header).merge(TransactionHeader.in_region(region)) }

  def self.search(q)
    where(arel_table[:customer_reference].matches("%#{q}%").or(arel_table[:reference_1].matches("%#{q}%")))
  end
end
