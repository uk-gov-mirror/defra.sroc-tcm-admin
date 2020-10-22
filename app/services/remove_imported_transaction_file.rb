# frozen_string_literal: true

class RemoveImportedTransactionFile < ServiceObject
  attr_reader :transaction_header

  def initialize(params = {})
    super()
    @transaction_header = TransactionHeaderPresenter.new(params.fetch(:transaction_header))
    @remover = params.fetch(:remover)
    @removal_reason = params.fetch(:removal_reason, "")
    @removal_reference = params.fetch(:removal_reference, "")
  end

  def call
    if check_params
      TransactionHeader.transaction do
        @transaction_header.update_attributes!(
          removed: true,
          removed_by: @remover,
          removed_at: Time.zone.now,
          removal_reference: @removal_reference,
          removal_reason: @removal_reason
        )
        @transaction_header.transaction_details.destroy_all
        @result = true
      end
    else
      @result = false
    end
    self
  end

  def check_params
    if !@transaction_header.can_be_removed?
      @transaction_header.errors.add(:base, "This file cannot be removed")
      false
    elsif @removal_reason.blank?
      @transaction_header.errors.add(:removal_reason,
                                     "^You must enter a reason for the removal")
      false
    else
      true
    end
  end
end
