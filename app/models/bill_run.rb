class BillRun < ApplicationRecord
  has_many :regimes
  has_many :regions
  has_many :sroc

  validates :bill_run_id, presence: true, uniqueness: true

end
