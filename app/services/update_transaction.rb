# frozen_string_literal: true

class UpdateTransaction < ServiceObject
  include RegimePresenter

  attr_reader :transaction

  def initialize(params = {})
    @params = params
  end

  def call
    attrs = @params.fetch(:attributes)
    user = @params.fetch(:user)
    # only get one attribute change at a time through the front-end
    if attrs.has_key?(:category)
      UpdateCategory.call(transaction: transaction,
                          category: attrs.fetch(:category),
                          user: user)
    elsif attrs.has_key?(:temporary_cessation)
      if str_to_bool(attrs.fetch(:temporary_cessation))
        ApplyTemporaryCessation.call(transaction: transaction, user: user)
      else
        RemoveTemporaryCessation.call(transaction: transaction, user: user)
      end
    elsif attrs.has_key?(:excluded)
      if str_to_bool(attrs.fetch(:excluded))
        ExcludeTransaction.call(transaction: transaction,
                                reason: attrs.fetch(:excluded_reason),
                                user: user)
      else
        UnexcludeTransaction.call(transaction: transaction, user: user)
      end
    elsif attrs.has_key?(:approved_for_billing)
      if str_to_bool(attrs.fetch(:approved_for_billing))
        ApproveTransaction.call(transaction: transaction, approver: user)
      else
        UnapproveTransaction.call(transaction: transaction, approver: user)
      end
    else
      @result = false
      self
    end
  end

  def transaction
    @transaction ||= @params.fetch(:transaction)
  end
end
