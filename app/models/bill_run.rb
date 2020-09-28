class BillRun < ApplicationRecord
  has_one :regimes
  has_one :regions
  has_one :sroc

  validates :bill_run_id, presence: true, uniqueness: true
end
