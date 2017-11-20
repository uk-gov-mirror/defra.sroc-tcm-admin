class TransactionHeader < ApplicationRecord
  belongs_to :regime, inverse_of: :transaction_headers
  has_many :transaction_details, inverse_of: :transaction_header, dependent: :destroy

  validates :feeder_source_code, inclusion: { in: %w[ PAS CFD WML ] }
  validates :region, presence: true
  validates :file_type_flag, inclusion: { in: %w[ C I ] }
  validates :file_sequence_number, presence: true
  validates :generated_at, presence: true

  def self.in_region(region)
    where(region: region)
  end

  def file_reference
    "#{feeder_source_code}#{region}#{file_type_flag}#{"%05d" % file_sequence_number}"
  end
end
