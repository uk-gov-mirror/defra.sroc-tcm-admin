# frozen_string_literal: true

class SequenceCounter < ApplicationRecord
  belongs_to :regime, inverse_of: :sequence_counters

  validates :region, presence: true, uniqueness: { scope: :regime_id }
  validates :file_number, presence: true
  validates :invoice_number, presence: true

  def self.next_file_number(regime, region)
    val = nil
    SequenceCounter.transaction do
      sequencer = SequenceCounter.lock.find_or_create_by(regime_id: regime.id,
                                                         region: region.upcase)

      val = sequencer.file_number
      sequencer.file_number += 1
      sequencer.save!
    end
    val
  end

  def self.next_invoice_number(regime, region)
    val = nil
    SequenceCounter.transaction do
      sequencer = SequenceCounter.lock.find_or_create_by(regime_id: regime.id,
                                                         region: region.upcase)

      val = sequencer.invoice_number
      sequencer.invoice_number += 1
      sequencer.save!
    end
    val
  end
end
