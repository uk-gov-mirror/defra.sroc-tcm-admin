class RegimeUser < ApplicationRecord
  belongs_to :regime, inverse_of: :regime_users
  belongs_to :user, inverse_of: :regime_users
end
