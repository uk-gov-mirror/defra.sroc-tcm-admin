class TransactionDetail < ApplicationRecord
  belongs_to :transaction_header, inverse_of: :transaction_details

  validates :sequence_number, presence: true
  validates :customer_reference, presence: true
  validates :line_amount, presence: true
  validates :unit_of_measure_price, presence: true
end
