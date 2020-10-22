# frozen_string_literal: true

class ExportDataFile < ApplicationRecord
  belongs_to :regime, inverse_of: :export_data_file

  before_validation :generate_filename, on: :create

  validates :filename, presence: true
  enum status: %i[pending generating success failed]

  private

  def generate_filename
    self.filename = "#{regime.slug}_transactions.csv".downcase
  end
end
