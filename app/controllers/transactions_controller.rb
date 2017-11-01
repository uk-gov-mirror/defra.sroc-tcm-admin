# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show, :edit, :update]

  # GET /regimes/:regime_id/transactions
  # GET /regimes/:regime_id/transactions.json
  def index
    region = params.fetch(:region, 'all')
    q = params.fetch(:search, "")
    pg = params.fetch(:page, 1)
    per_pg = params.fetch(:per_page, 10)

    @transactions = transaction_store.transactions_to_be_billed(
      q,
      pg,
      per_pg,
      region,
      params.fetch(:sort, :customer_reference),
      params.fetch(:sort_direction, 'asc'))

    summary = transaction_store.transactions_to_be_billed_summary(q, region)
    @transactions = present_transactions(@transactions, summary)
    respond_to do |format|
      format.html do
        render
      end
      format.js
      format.json do
        render json: @transactions
      end
    end
  end

  # GET /regimes/:regime_id/transactions/1
  # GET /regimes/:regime_id/transactions/1.json
  def show
  end

  # GET /regimes/:regimes_id/transactions/1/edit
  def edit
    @related_transactions = transaction_store.transactions_related_to(@transaction)
  end

  # PATCH/PUT /regimes/:regimes_id/transactions/1
  # PATCH/PUT /regimes/:regimes_id/transactions/1.json
  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to edit_regime_transaction_path(@regime, @transaction),
                      notice: 'Transaction  was successfully updated.' }
        format.json { render json: { message: 'Transaction updated' }, status: :ok, location: regime_transaction_path(@regime, @transaction) }
      else
        format.html { render :edit }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def present_transactions(transactions, summary)
      name = "#{@regime.slug}_transaction_detail_presenter".camelize
      presenter = str_to_class(name) || TransactionDetailPresenter
      arr = Kaminari.paginate_array(presenter.wrap(transactions),
                                    total_count: transactions.total_count,
                                    limit: transactions.limit_value,
                                    offset: transactions.offset_value)
      {
        pagination: {
          current_page: arr.current_page,
          prev_page: arr.prev_page,
          next_page: arr.next_page,
          per_page: arr.limit_value,
          total_pages: arr.total_pages,
          total_count: arr.total_count
        },
        transactions: arr,
        summary: summary
      }
    end

    def str_to_class(name)
      begin
        name.constantize
      rescue NameError => e
        nil
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_regime
      # FIXME: this is just to avoid not having a regime set on entry
      # this will be replaced by using user regimes roles/permissions
      if params.fetch(:regime_id, nil)
        @regime = Regime.find_by!(slug: params[:regime_id])
      else
        @regime = Regime.first
      end
    end

    def set_transaction
      set_regime
      @transaction = transaction_store.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction_detail).permit(:category)
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end
end
