# frozen_string_literal: true

class TransactionsController < ApplicationController
  include RegimeScope, FinancialYear, CsvExporter, QueryTransactions
  before_action :set_regime, only: [:index, :approve]
  before_action :set_transaction, only: [:show, :edit, :update]
  before_action :set_current_user, only: [:update, :approve]

  # GET /regimes/:regime_id/transactions
  # GET /regimes/:regime_id/transactions.json
  def index
    # regions = transaction_store.unbilled_regions
    # mode = params.fetch(:view_mode, 'unbilled')
    # if mode == 'unbilled'
      # @region = params.fetch(:region, cookies[:region])
      # @region = regions.first if @region.blank? #unless regions.include? @region
    # else
    regions = RegionsQuery.call(regime: @regime)
    @region = params.fetch(:region, cookies.fetch(:region, ''))
    @region = regions.first if @region.blank? || @region == 'all'

    # end

    # q = params.fetch(:search, cookies[:search] || '')
    # sort_col = params.fetch(:sort, cookies[:sort] || '')
    # sort_dir = params.fetch(:sort_direction, cookies[:sort_direction] || 'asc')
      pg = params.fetch(:page, cookies.fetch(:page, 1))
      per_pg = params.fetch(:per_page, cookies.fetch(:per_page, 10))

    @financial_years = Query::UnbilledFinancialYears.call(regime: @regime)
    @financial_year = params.fetch(:fy, cookies.fetch(:fy, ''))
    @financial_year = '' unless @financial_years.include? @financial_year

    @transactions = Query::TransactionsToBeBilled.call(query_params)
    # regime: @regime,
    #                                                  region: @region,
    #                                                  sort_column: sort_col,
    #                                                  sort_direction: sort_dir,
    #                                                  search: q)

    # @transactions = transaction_store.transactions_to_be_billed(
    #   q,
    #   pg,
    #   per_pg,
    #   @region,
    #   sort_col,
    #   sort_dir
    # )

    # don't want to display these here for now
    # summary = transaction_store.transactions_to_be_billed_summary(q, region)
    summary = nil

    respond_to do |format|
      format.html do
        @transactions = present_transactions(@transactions.page(pg).per(per_pg))
        # @categories = current_permit_categories 
        if request.xhr?
          render partial: "table", locals: { transactions: @transactions }
        else
          render
        end
      end
      # format.json do
      #   @transactions = present_transactions_for_json(@transactions.page(pg).per(per_pg),
      #                                                 @region,
      #                                                 regions,
      #                                                 summary)
      #   render json: @transactions
      # end
      format.csv do
        send_data csv.export(presenter.wrap(@transactions.unexcluded.limit(15000))),
          csv_opts
      end
    end
  end

  # GET /regimes/:regime_id/transactions/1
  # GET /regimes/:regime_id/transactions/1.json
  def show
    @related_transactions = transaction_store.transactions_related_to(@transaction)
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
              locals: { transaction: presenter.new(@transaction, current_user) }
          else
            redirect_to edit_regime_transaction_path(@regime, @transaction),
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
            redirect_to edit_regime_transaction_path(@regime, @transaction),
              notice: 'Transaction was not updated.'
          end
        end
        format.json { render json: @transaction, status: :unprocessable_entity }
      end
    end
  end

  # PUT - approve all matching eligible transactions
  def approve
    regions = RegionsQuery.call(regime: @regime)
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
    def current_permit_categories
      permit_store.active_list_for_selection(current_financial_year).
        pluck(:code).map do |c|
          { value: c, label: c }
        end
    end

    def update_transaction
      if @transaction.updateable?
        if @transaction.update(transaction_params)
        # @transaction.assign_attributes(transaction_params)
        # if @transaction.valid?
          # category_changes = @transaction.changes[:category]
          # tc_changes = @transaction.changes[:temporary_cessation]
          category_changes = @transaction.previous_changes[:category]
          tc_changes = @transaction.previous_changes[:temporary_cessation]
          exclusion_changes = @transaction.previous_changes[:excluded]

          if tc_changes 
            if @transaction.category.present?
              @transaction.charge_calculation = get_charge_calculation
              if @transaction.charge_calculation_error?
                @transaction.temporary_cessation = tc_changes[0]
                @transaction.tcm_charge = nil
              else
                @transaction.tcm_charge = TransactionCharge.extract_correct_charge(@transaction)
              end
            else
              # we might have an error from a previous interaction so remove it
              @transaction.charge_calculation = nil
            end
            @transaction.save
            # if @transaction.save
            #   auditor.log_modify(@transaction)
            #   true
            # else
            #   false
            # end
          elsif category_changes
            # always get charge when category changes unless blank
            @transaction.charge_calculation = get_charge_calculation
            # restore category if charge calc error
            if @transaction.charge_calculation_error?
              @transaction.category = category_changes[0]
              @transaction.tcm_charge = nil
            else
              # extract charge calculation and correctly sign it
              @transaction.tcm_charge = TransactionCharge.extract_correct_charge(@transaction)
              if @transaction.suggested_category
                @transaction.suggested_category.update_attributes(overridden: true)
              end
            end
            # auditor.log_modify(@transaction)
            @transaction.save
            # if @transaction.save
            #   auditor.log_modify(@transaction)
            #   true
            # else
            #   false
            # end
          elsif exclusion_changes
            if exclusion_changes[0] == true
              # was excluded now reinstate
              @transaction.charge_calculation = get_charge_calculation
              unless @transaction.charge_calculation_error?
                @transaction.tcm_charge = TransactionCharge.extract_correct_charge(@transaction)
              end
            else
              # become excluded
              @transaction.charge_calculation = nil
              @transaction.tcm_charge = nil
            end
            @transaction.save
          else
            # nothing changing but don't want to generate an error
            true
          end
        else
          false
        end
      else
        @transaction.errors.add(:category, "Transaction cannot be updated")
        false
      end
    end

    def get_charge_calculation
      TransactionCharge.invoke_charge_calculation(calculator,
                                                  presenter.new(@transaction)) if @transaction.category.present?
    end

    def present_transactions(transactions)
      Kaminari.paginate_array(presenter.wrap(transactions, current_user),
                              total_count: transactions.total_count,
                              limit: transactions.limit_value,
                              offset: transactions.offset_value)
    end

    def present_transactions_for_json(transactions, selected_region, regions, summary)
      arr = present_transactions(transactions)
      # arr = Kaminari.paginate_array(presenter.wrap(transactions, current_user),
      #                               total_count: transactions.total_count,
      #                               limit: transactions.limit_value,
      #                               offset: transactions.offset_value)
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
        selected_region: selected_region,
        regions: region_options(regions)
      }
    end

    def region_options(regions)
      regions.map { |r| { label: r, value: r } }
    end

    def set_transaction
      set_regime
      @transaction = transaction_store.find(params[:id])
    end

    def transaction_params
      params.require(:transaction_detail).permit(:category, :temporary_cessation,
                                                 :excluded, :excluded_reason,
                                                 :approved_for_billing)
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime, current_user)
    end

    def calculator
      @calculator ||= CalculationService.new
    end

    def auditor
      @auditor ||= AuditService.new(current_user)
    end

    def permit_store
      @permit_store ||= PermitStorageService.new(@regime, current_user)
    end

    def set_current_user
      Thread.current[:current_user] = current_user
    end
end
