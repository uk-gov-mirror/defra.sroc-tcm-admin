class Regime < ApplicationRecord
  has_many :transaction_headers, inverse_of: :regime, dependent: :destroy

  validates :name, presence: true
end
