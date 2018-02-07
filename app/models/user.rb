class User < ApplicationRecord
  enum role: [:billing, :admin]
  enum active_regime: [:cfd, :pas, :wml]

  has_many :regime_users, inverse_of: :user, dependent: :destroy
  has_many :regimes, -> { merge(RegimeUser.enabled) }, through: :regime_users

  after_save :ensure_a_default_regime_is_set

  accepts_nested_attributes_for :regime_users

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :recoverable, :rememberable,
    :trackable, :lockable, :timeoutable, :registerable
    # :validatable,

  validates :email, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validate :at_least_one_regime_selected
  validate :password_complexity

  def full_name
    first_name + " " + last_name
  end

  def can_reinvite?
    persisted? && enabled? && invitation_accepted_at.nil?
  end

  def active_for_authentication?
    enabled?
  end

  def selected_regime
    if active_regime.nil?
      set_default_regime
    else
      regimes.find_by(slug: active_regime)
    end
  end

  def set_selected_regime(regime_id)
    reg = regimes.find_by(slug: regime_id)
    if reg
      send("#{reg.to_param}!") unless active_regime == reg.to_param
      reg
    else
      set_default_regime
    end
  end

  private
  def set_default_regime
    reg = regimes.order(:title).first
    send("#{reg.to_param}!")
    reg
  end

  def at_least_one_regime_selected
    selected = regime_users.select { |ru| ru.enabled? }.count
    errors.add :regime, "^Access to at least one Regime is required" if selected.zero?
  end

  def ensure_a_default_regime_is_set
    set_default_regime unless regimes.map(&:slug).include? active_regime
  end

  def password_complexity
    if password.present?
      if !password.match /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/
        errors.add :password, "does not meet complexity requirements"
      end
    end
  end
end
