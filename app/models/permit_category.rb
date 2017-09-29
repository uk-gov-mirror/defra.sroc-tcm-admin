class PermitCategory < ApplicationRecord
  belongs_to :regime

  validates :code, presence: true, uniqueness: { scope: :regime_id }
  validates :status, presence: true
  validates :display_order, presence: true
end
