class TransactionDetail < ApplicationRecord
  belongs_to :transaction_header, inverse_of: :transaction_details
end
