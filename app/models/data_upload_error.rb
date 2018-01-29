class DataUploadError < ApplicationRecord
  belongs_to :annual_billing_data_file, inverse_of: :data_upload_errors

  validates :line_number, presence: true
  validates :message, presence: true
end
