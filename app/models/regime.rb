class Regime < ApplicationRecord
  has_many :transaction_headers, inverse_of: :regime, dependent: :destroy
  has_many :transaction_details, through: :transaction_headers
  has_many :permits, inverse_of: :regime, dependent: :destroy
  has_many :permit_categories, inverse_of: :regime, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  # this is killing older migration
  # validates :title, presence: true
  before_save :generate_slug

  def to_param
    slug
  end

  def waste_or_installations?
    waste? || installations?
  end

  def waste?
    slug == 'wml'
  end

  def installations?
    slug == 'pas'
  end

  def water_quality?
    slug == 'cfd'
  end

private
  def generate_slug
    self.slug = name.parameterize.downcase
  end
end
