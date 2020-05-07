class ApproveTransaction < ServiceObject
  attr_reader :transaction

  def initialize(params = {})
    @transaction = params.fetch(:transaction)
    @approver = params.fetch(:approver)
  end

  def call
    if @transaction.ready_for_approval?
      @result = @transaction.update(approved_for_billing: true,
                                               approver: @approver,
                                               approved_for_billing_at: Time.zone.now)
    else
      @result = false
    end
    self
  end
end
