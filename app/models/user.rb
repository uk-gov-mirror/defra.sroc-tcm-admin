class User < ApplicationRecord
  enum role: [:billing, :admin, :read_only, :read_only_export]
  enum active_regime: [:cfd, :pas, :wml]

  has_many :regime_users, inverse_of: :user, dependent: :destroy
  has_many :regimes, -> { merge(RegimeUser.enabled) }, through: :regime_users
  has_many :audit_logs, inverse_of: :user
  has_many :transaction_files, inverse_of: :user
  has_many :approved_transactions, class_name: 'TransactionDetail', foreign_key: :approver_id, inverse_of: :approver
  after_save :ensure_a_default_regime_is_set

  accepts_nested_attributes_for :regime_users

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :recoverable, :rememberable,
    :trackable, :lockable, :timeoutable, :registerable, :validatable

  validates :email, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validate :at_least_one_regime_selected
  validate :password_complexity

  def self.system_account
    find_by!(email: 'system@example.com')
  end

  def self.ordered_roles
    [:read_only, :read_only_export, :billing, :admin]
  end

  def self.search(str)
    m = "%#{sanitize_sql_like(str)}%"
    where(arel_table[:first_name].matches(m).
          or(arel_table[:last_name].matches(m)))
  end

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

  def can_read_only?
    read_only? || read_only_export?
  end

  def can_export_data?
    admin? || billing? || read_only_export?
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
