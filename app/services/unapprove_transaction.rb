class UnapproveTransaction < ServiceObject
  attr_reader :transaction

  def initialize(params = {})
    @transaction = params.fetch(:transaction)
    @approver = params.fetch(:approver)
  end

  def call
    if @transaction.approved?
      @result = @transaction.update(approved_for_billing: false,
                                               approver: @approver,
                                               approved_for_billing_at: Time.zone.now)
    else
      @result = false
    end
    self
  end
end
