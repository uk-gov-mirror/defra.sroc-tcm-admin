class Regime < ApplicationRecord
  has_many :transaction_headers, inverse_of: :regime, dependent: :destroy
  has_many :permits, inverse_of: :regime, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  before_save :generate_slug

  def to_param
    slug
  end

private
  def generate_slug
    self.slug = name.parameterize.downcase
  end
end
