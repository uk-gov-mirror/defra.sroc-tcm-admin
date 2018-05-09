class ExclusionReason < ApplicationRecord
  belongs_to :regime, inverse_of: :exclusion_reasons

  validates :reason, presence: true, uniqueness: { scope: :regime_id }
end
