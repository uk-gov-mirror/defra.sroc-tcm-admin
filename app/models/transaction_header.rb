class TransactionHeader < ApplicationRecord
  belongs_to :regime, inverse_of: :transaction_headers
  has_many :transaction_details, inverse_of: :transaction_header, dependent: :destroy
end
