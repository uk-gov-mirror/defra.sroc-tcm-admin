# frozen_string_literal: true

class HistoryController < ApplicationController
  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]

  # GET /regimes/:regime_id/history
  # GET /regimes/:regime_id/history.json
  def index
    region = params.fetch(:region, 'all')
    q = params.fetch(:search, "")

    @transactions = transaction_store.transaction_history(
      q,
      params.fetch(:page, 1),
      params.fetch(:per_page, 10),
      region,
      params.fetch(:sort, :file_reference),
      params.fetch(:sort_direction, 'asc'))
  end

  # GET /regimes/:regime_id/history/1
  # GET /regimes/:regime_id/history/1.json
  def show
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

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end
end
