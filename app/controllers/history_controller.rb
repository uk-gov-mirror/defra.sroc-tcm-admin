# frozen_string_literal: true

class HistoryController < ApplicationController
  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]

  # GET /regimes/:regime_id/history
  # GET /regimes/:regime_id/history.json
  def index
    respond_to do |format|
      format.html do
        render
      end
      format.js
      format.json do
        region = params.fetch(:region, 'all')
        q = params.fetch(:search, "")
        pg = params.fetch(:page, 1)
        per_pg = params.fetch(:per_page, 10)

        @transactions = transaction_store.transaction_history(
          q,
          pg,
          per_pg,
          region,
          params.fetch(:sort, :customer_reference),
          params.fetch(:sort_direction, 'asc'))

        @transactions = present_transactions(@transactions)
        render json: @transactions
      end
    end
  end

  # GET /regimes/:regime_id/history/1
  # GET /regimes/:regime_id/history/1.json
  def show
  end

  private
    def present_transactions(transactions)
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
        transactions: arr
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

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end
end
