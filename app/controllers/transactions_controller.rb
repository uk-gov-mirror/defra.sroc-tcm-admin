# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show, :edit, :update]

  # GET /regimes/:regime_id/transactions
  # GET /regimes/:regime_id/transactions.json
  def index
    region = params.fetch(:region, 'all')
    q = params.fetch(:search, "")

    @transactions = transaction_store.transactions_to_be_billed(
      q,
      params.fetch(:page, 1),
      params.fetch(:per_page, 10),
      region)
    @summary = transaction_store.transactions_to_be_billed_summary(q, region)
  end

  # GET /regimes/:regime_id/transactions/1
  # GET /regimes/:regime_id/transactions/1.json
  def show
  end

  # GET /regimes/:regimes_id/transactions/1/edit
  def edit
  end

  # PATCH/PUT /regimes/:regimes_id/transactions/1
  # PATCH/PUT /regimes/:regimes_id/transactions/1.json
  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to regime_transaction_path(@regime, @transaction), notice: 'Permit was successfully updated.' }
        format.json { render :show, status: :ok, location: regime_transaction_path(@regime, @transaction) }
      else
        format.html { render :edit }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_regime
      @regime = Regime.find_by!(slug: params[:regime_id])
    end

    def set_transaction
      set_regime
      @transaction = transaction_store.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).
        permit(:transaction_reference, :transaction_category, :effective_date, :status)
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end
end
