class User < ApplicationRecord
  enum role: [:billing, :admin]
  has_many :regime_users, inverse_of: :user, dependent: :destroy
  has_many :regimes, through: :regime_users

  accepts_nested_attributes_for :regime_users

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :recoverable, :rememberable,
    :trackable, :lockable, :timeoutable
    # :validatable,

  validate :password_complexity

  def full_name
    first_name + " " + last_name
  end

  def active_for_authentication?
    enabled?
  end

  def password_complexity
    if password.present?
      if !password.match /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/
        errors.add :password, "Password does not meet complexity requirements"
      end
    end
  end
end
