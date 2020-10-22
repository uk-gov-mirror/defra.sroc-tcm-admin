# frozen_string_literal: true

class Permit < ApplicationRecord
  belongs_to :regime, inverse_of: :permits

  validates :permit_reference, presence: true
  validates :permit_category, presence: true
  validates :effective_date, presence: true
  validates :status, presence: true
end
