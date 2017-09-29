class TransactionHeader < ApplicationRecord
  belongs_to :regime, inverse_of: :transaction_headers
  has_many :transaction_details, inverse_of: :transaction_header, dependent: :destroy

  validates :feeder_source_code, presence: true
  validates :region, presence: true
  validates :file_sequence_number, presence: true
  validates :generated_at, presence: true

  def self.in_region(region)
    if region == 'all'
      all
    else
      where(region: region)
    end
  end
end
