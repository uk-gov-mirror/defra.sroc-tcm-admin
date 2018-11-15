class TransactionDetail < ApplicationRecord
  include Auditable

  audit_events :update
  audit_attributes [ :category,
                     :temporary_cessation,
                     :charge_calculation,
                     :tcm_charge,
                     :variation,
                     :excluded,
                     :excluded_reason,
                     :approved_for_billing ]

  belongs_to :transaction_header, inverse_of: :transaction_details
  has_one :regime, through: :transaction_header
  belongs_to :transaction_file, inverse_of: :transaction_details, required: false
  has_one :suggested_category, inverse_of: :transaction_detail, dependent: :destroy
  has_many :matched_transactions, class_name: 'SuggestedCategory', foreign_key: :matched_transaction_id, dependent: :nullify
  belongs_to :approver, class_name: 'User', inverse_of: :approved_transactions, required: false

  validates :sequence_number, presence: true
  validates :customer_reference, presence: true
  validates :line_amount, presence: true
  validates :unit_of_measure_price, presence: true

  scope :unbilled, -> { where(status: 'unbilled') }
  scope :retrospective, -> { where(status: 'retrospective') }
  scope :historic, -> { where(status: 'billed') }

  scope :excluded, -> { where(excluded: true) }
  scope :unexcluded, -> { where(excluded: false) }
  scope :historic_excluded, -> { where(status: 'excluded') }

  scope :unbilled_exclusions, -> { where(status: 'unbilled', excluded: true) }

  scope :with_charge_errors, -> {
    where("(charge_calculation -> 'calculation' ->> 'messages') is not null")
  }
  scope :credits, -> { where(arel_table[:line_amount].lt 0) }
  scope :invoices, -> { where(arel_table[:line_amount].gteq 0) }
  scope :region, ->(region) { joins(:transaction_header).
                              merge(TransactionHeader.in_region(region)) }
  # scope :without_charge, -> { where(charge_calculation: nil).
  #                             or(TransactionDetail.with_charge_errors) }
  scope :with_charge, -> { where.not(tcm_charge: nil) }
  scope :without_charge, -> { where(tcm_charge: nil) }
  scope :financial_year, ->(fy) { where(tcm_financial_year: fy) }
  scope :approved, -> { where(approved_for_billing: true) }
  scope :unapproved, -> { where(approved_for_billing: false) }

  def self.search(q)
    m = "%#{q}%"
    where(arel_table[:customer_reference].matches(m).
          or(arel_table[:reference_1].matches(m)).
          or(arel_table[:transaction_reference].matches(m)))
  end

  def self.history_search(q)
    m = "%#{q}%"
    where(arel_table[:customer_reference].matches(m).
          or(arel_table[:reference_1].matches(m)).
          or(arel_table[:reference_2].matches(m)).
          or(arel_table[:transaction_reference].matches(m)).
          or(arel_table[:category].matches(m)).
          or(arel_table[:original_filename].matches(m)).
          or(arel_table[:generated_filename].matches(m)).
          or(arel_table[:tcm_transaction_reference].matches(m)))
  end

  def self.retrospective_search(q)
    m = "%#{q}%"
    where(arel_table[:customer_reference].matches(m).
          or(arel_table[:reference_1].matches(m)).
          or(arel_table[:transaction_reference].matches(m)))
  end

  def self.exclusion_search(q)
    m = "%#{q}%"
    where(arel_table[:customer_reference].matches(m).
          or(arel_table[:reference_1].matches(m)).
          or(arel_table[:reference_2].matches(m)).
          or(arel_table[:transaction_reference].matches(m)).
          or(arel_table[:original_filename].matches(m)).
          or(arel_table[:excluded_reason].matches(m)))
  end

  def updateable?
    unbilled?
  end

  def approved?
    approved_for_billing?
  end

  def ready_for_approval?
    unbilled? && !approved? && charge_calculated? && !charge_calculation_error?
  end

  def category_overridden?
    suggested_category && suggested_category.overridden?
  end

  def unbilled?
    status == 'unbilled'
  end

  def retrospective?
    status == 'retrospective'
  end

  def permanently_excluded?
    status == 'excluded'
  end

  def charge_calculated?
    charge_calculation.present?
  end

  def charge_calculation_error?
    charge_calculated? && charge_calculation["calculation"] && charge_calculation["calculation"]["messages"]
  end

  def credit?
    line_amount.negative?
  end

  def invoice?
    line_amount.positive?
  end
end
