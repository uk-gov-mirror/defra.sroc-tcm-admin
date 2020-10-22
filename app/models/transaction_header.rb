# frozen_string_literal: true

class TransactionHeader < ApplicationRecord
  belongs_to :regime, inverse_of: :transaction_headers
  has_many :transaction_details, inverse_of: :transaction_header, dependent: :destroy
  belongs_to :removed_by, class_name: "User", inverse_of: :removed_transaction_files, required: false
  validates :feeder_source_code, inclusion: { in: %w[PAS CFD WML] }
  validates :region, presence: true
  validates :file_type_flag, inclusion: { in: %w[C I] }
  validates :file_sequence_number, presence: true
  validates :generated_at, presence: true

  before_create :generate_file_reference

  def self.in_region(region)
    where(region: region)
  end

  def self.search(query)
    m = "%#{sanitize_sql_like(query)}%"
    where(arel_table[:file_reference].matches(m))
  end

  private

  def generate_file_reference
    sequence_number = format("%<sequence>05d", sequence: file_sequence_number)
    self.file_reference = "#{feeder_source_code}#{region}#{file_type_flag}#{sequence_number}"
  end
end
