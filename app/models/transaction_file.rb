class TransactionFile < ApplicationRecord
  belongs_to :regime, inverse_of: :transaction_files
  has_many :transaction_details, inverse_of: :transaction_file

  validates :region, presence: true
  after_create :set_file_id

  def path
    File.join(regime.to_param, filename)
  end

  def filename
    @filename ||= "#{base_filename}.dat".downcase
  end

  def base_filename
    @base_filename ||= "#{regime.to_param}#{region}I#{file_id}".upcase
  end
private
  def set_file_id
    update_attributes(file_id: generate_file_id)
  end

  def generate_file_id
    fid = "#{SequenceCounter.next_file_number(regime, region).to_s.rjust(5, "0")}"
    fid += 'T' unless retrospective?
    fid
  end
end
