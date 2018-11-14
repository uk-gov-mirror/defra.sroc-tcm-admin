# frozen_string_literal: true

class TransactionsController < ApplicationController
  include RegimeScope, FinancialYear, CsvExporter, ViewModelBuilder
  before_action :set_regime, only: [:index, :approve]
  before_action :set_transaction, only: [:show, :edit, :update]
  # before_action :set_current_user, only: [:update, :approve]

  # GET /regimes/:regime_id/transactions
  # GET /regimes/:regime_id/transactions.json
  def index
    @view_model = build_transactions_view_model

    respond_to do |format|
      format.html do
        if request.xhr?
          render partial: "table", locals: { view_model: @view_model }
        else
          render
        end
      end
      format.csv do
        send_data csv.export(@view_model.csv_transactions), csv_opts
      end
    end
  end

  # GET /regimes/:regime_id/transactions/1
  # GET /regimes/:regime_id/transactions/1.json
  def show
    @related_transactions = Query::RelatedTransactions.call(transaction: @transaction)
    @exclusion_reasons = Query::Exclusions.call(regime: @regime)
  end

  # GET /regimes/:regimes_id/transactions/1/edit
  def edit
    # @related_transactions = transaction_store.transactions_related_to(@transaction)
  end

  # PATCH/PUT /regimes/:regimes_id/transactions/1
  # PATCH/PUT /regimes/:regimes_id/transactions/1.json
  def update
    respond_to do |format|
      result = UpdateTransaction.call(transaction: @transaction,
                                      attributes: transaction_params,
                                      user: current_user)
      @transaction = result.transaction

      if result.success?
        format.html do
          if request.xhr?
            render partial: "#{@regime.to_param}_transaction",
              locals: { transaction: presenter.new(@transaction, current_user),
                        data_path: regime_transaction_path(@regime, @transaction) }
          else
            redirect_to regime_transaction_path(@regime, @transaction),
              notice: 'Transaction was successfully updated.'
          end
        end
        format.json {
          render json: { transaction: presenter.new(@transaction, current_user),
                         message: 'Transaction updated'
                        },
                        status: :ok,
                        location: regime_transaction_path(@regime, @transaction)
        }
      else
        format.html do
          if request.xhr?
            render partial: "#{@regime.to_param}_transaction",
              locals: { transaction: presenter.new(@transaction, current_user) }
          else
            redirect_to regime_transaction_path(@regime, @transaction),
              notice: 'Transaction was not updated.'
          end
        end
        format.json { render json: @transaction, status: :unprocessable_entity }
      end
    end
  end

  # PUT - approve all matching eligible transactions
  def approve
    regions = Query::Regions.call(regime: @regime)
    # regions = transaction_store.unbilled_regions
    @region = params.fetch(:region, cookies[:region])
    msg = ""
    
    result = if regions.include? @region
               true
             else
               msg = "Region #{@region} is not valid"
               false
             end

    # error if blank or no legit region specified
    count = 0

    if result
      q = params.fetch(:search, '')
      approval = ApproveMatchingTransactions.call(regime: @regime,
                                                  region: @region,
                                                  search: q,
                                                  user: current_user)
      result = approval.success?
      count = approval.count
    end

    respond_to do |format|
      format.json do
        render json: { success: result, message: msg, count: count }
      end
      format.any do
        head :not_acceptable
      end
    end
  end

  private
    def present_transactions(transactions)
      Kaminari.paginate_array(presenter.wrap(transactions, current_user),
                              total_count: transactions.total_count,
                              limit: transactions.limit_value,
                              offset: transactions.offset_value)
    end

    def set_transaction
      set_regime
      @transaction = Query::FindTransaction.call(regime: @regime,
                                                 transaction_id: params[:id])
    end

    def transaction_params
      params.require(:transaction_detail).permit(:category, :temporary_cessation,
                                                 :excluded, :excluded_reason,
                                                 :approved_for_billing)
    end
end
