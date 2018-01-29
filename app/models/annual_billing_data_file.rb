class AnnualBillingDataFile < ApplicationRecord
  belongs_to :regime, inverse_of: :annual_billing_data_files
  has_many :data_upload_errors, inverse_of: :annual_billing_data_file, dependent: :destroy

  validates :filename, presence: true
  validates :number_of_records, numericality: { only_integer: true }
  validates :status, inclusion: { in: %w[ new uploaded processing completed failed ] }

  def file_types
    AnnualBillingDataFileFormat::FileTypes
  end

  def log_error(line, msg)
    data_upload_errors.create(line_number: line, message: msg)
  end

  def state
    machine = Bstard.define do |fsm|
      fsm.initial status
      fsm.event :upload, :new => :uploaded
      fsm.event :process, :uploaded => :processing
      fsm.event :complete, :processing => :completed
      fsm.event :error, :processing => :failed, :new => :failed
      fsm.when :any do |_event, _prev_state, new_state|
        update_attribute(:status, new_state)
      end
    end
  end
  
  def finished_processing?
    s = state
    s.completed? || s.failed?
  end
end
