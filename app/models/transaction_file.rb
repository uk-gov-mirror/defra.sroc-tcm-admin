# frozen_string_literal: true

class TransactionFile < ApplicationRecord
  include Auditable

  audit_events :create

  belongs_to :regime, inverse_of: :transaction_files
  has_many :transaction_details, inverse_of: :transaction_file
  belongs_to :user, inverse_of: :transaction_files

  validates :region, presence: true
  validates :user_id, presence: true

  after_create :set_file_id

  scope :pre_sroc, -> { where(retrospective: true) }
  scope :post_sroc, -> { where(retrospective: false) }

  def self.search(str)
    m = "%#{sanitize_sql_like(str)}%"
    where(arel_table[:file_reference].matches(m))
  end

  def path
    File.join(regime.to_param, filename)
  end

  def filename
    unless @filename
      base = base_filename
      base.downcase! if regime.water_quality?
      ext = regime.waste? ? ".DAT" : ".dat"
      @filename = "#{base}#{ext}"
    end
    @filename
  end

  def base_filename
    @base_filename ||= "#{regime.to_param}#{region}I#{file_id}".upcase
  end

  def generated_by
    user&.full_name
  end

  private

  def set_file_id
    self.file_id = generate_file_id
    self.file_reference = base_filename
    save!
  end

  def generate_file_id
    fid = SequenceCounter.next_file_number(regime, region).to_s.rjust(5, "0").to_s
    fid += "T" unless retrospective?
    fid
  end
end
