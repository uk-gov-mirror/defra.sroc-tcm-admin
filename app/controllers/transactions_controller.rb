# frozen_string_literal: true

class TransactionsController < ApplicationController
  include ViewModelBuilder
  include CsvExporter
  include FinancialYear
  include RegimeScope
  before_action :set_regime, only: %i[index approve]
  before_action :set_transaction, only: %i[show edit update audit]
  before_action :read_only_user_check!, only: %i[update approve audit]

  # GET /regimes/:regime_id/transactions
  # GET /regimes/:regime_id/transactions.json
  def index
    @view_model = build_transactions_view_model

    respond_to do |format|
      format.html do
        render partial: "table", locals: { view_model: @view_model } if request.xhr?
      end
      format.csv do
        export_data_user_check!
        result = BatchCsvExport.call(regime: @regime,
                                     query: @view_model.fetch_transactions)
        if result.success?
          set_streaming_headers
          self.response_body = result.csv_stream
        end
      end
    end
  end

  # GET /regimes/:regime_id/transactions/1
  # GET /regimes/:regime_id/transactions/1.json
  def show
    @related_unbilled_transactions = Query::RelatedUnbilledTransactions.call(
      transaction: @transaction
    )
    @related_billed_transactions = Query::RelatedBilledTransactions.call(
      transaction: @transaction
    )

    @exclusion_reasons = Query::Exclusions.call(regime: @regime)
  end

  def audit
    result = ExtractAuditDetail.call(transaction: @transaction)
    @logs = result.audit_details
  end

  # GET /regimes/:regimes_id/transactions/1/edit
  def edit; end

  # PATCH/PUT /regimes/:regimes_id/transactions/1
  # PATCH/PUT /regimes/:regimes_id/transactions/1.json
  def update
    respond_to do |format|
      result = UpdateTransaction.call(transaction: @transaction,
                                      attributes: transaction_params,
                                      user: current_user)
      @transaction = result.transaction
      path = regime_transaction_path(@regime, @transaction)
      if result.success?
        format.html do
          if request.xhr?
            render partial: "#{@regime.to_param}_transaction",
                   locals: { transaction: presenter.new(@transaction, current_user),
                             data_path: path }
          else
            redirect_to path, notice: "Transaction was successfully updated."
          end
        end
        format.json do
          render json: { transaction: presenter.new(@transaction, current_user),
                         message: "Transaction updated" },
                 status: :ok,
                 location: path
        end
      else
        format.html do
          if request.xhr?
            render partial: "#{@regime.to_param}_transaction",
                   locals: { transaction: presenter.new(@transaction, current_user),
                             data_path: path }
          else
            redirect_to path, notice: "Transaction was not updated."
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
    fy = params.fetch(:fy, cookies[:fy])

    available_years = Query::FinancialYears.call(regime: @regime)
    fy = "" unless available_years.include? fy

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
      q = params.fetch(:search, "")
      approval = ApproveMatchingTransactions.call(regime: @regime,
                                                  region: @region,
                                                  financial_year: fy,
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
