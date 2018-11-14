class SuggestedCategory < ApplicationRecord
  enum confidence_level: [ :green, :amber, :red ]

  belongs_to :transaction_detail, inverse_of: :suggested_category
  belongs_to :matched_transaction, class_name: 'TransactionDetail', optional: true

  validates :confidence_level, inclusion: { in: %w[ red amber green ] }
  validates :suggestion_stage, presence: true
  validates :logic, presence: true
end
