class ApproveMatchingTransactions < ServiceObject
  attr_reader :transaction, :count

  def initialize(params = {})
    @regime = params.fetch(:regime)
    @region = params.fetch(:region)
    @search = params.fetch(:search)
    @user = params.fetch(:user)
    @count = 0
  end

  def call
    @result = false
    TransactionDetail.transaction do
      @result = update
    end
    self
  end

  private
  def update
    @regime.transaction_details.region(@region).unbilled.
      unexcluded.unapproved.with_charge.search(@search).each do |transaction|
      app = ApproveTransaction.call(transaction: transaction, approver: @user)
      if app.success?
        @count += 1
      else
        Rails.logger.debug("Failed to approve #{transaction.id}")
      end
    end
    true
  end
end
