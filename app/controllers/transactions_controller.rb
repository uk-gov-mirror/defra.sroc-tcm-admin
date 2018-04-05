# frozen_string_literal: true

class TransactionsController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show, :edit, :update]

  # GET /regimes/:regime_id/transactions
  # GET /regimes/:regime_id/transactions.json
  def index
    regions = transaction_store.unbilled_regions
    mode = params.fetch(:view_mode, 'unbilled')
    if mode == 'unbilled'
      @region = params.fetch(:region, regions.first)
      @region = regions.first unless regions.include? @region
    else
      @region = params.fetch(:region, '')
    end

    q = params.fetch(:search, "")

    respond_to do |format|
      format.html
      format.json do
        pg = params.fetch(:page, 1)
        per_pg = params.fetch(:per_page, 10)

        @transactions = transaction_store.transactions_to_be_billed(
          q,
          pg,
          per_pg,
          @region,
          params.fetch(:sort, :customer_reference),
          params.fetch(:sort_direction, 'asc'))

        # don't want to display these here for now
        # summary = transaction_store.transactions_to_be_billed_summary(q, region)
        summary = nil
        @transactions = present_transactions(@transactions, @region, regions, summary)
        render json: @transactions
      end
      format.csv do
        @transactions = transaction_store.transactions_to_be_billed_for_export(
          q,
          @region
        )
        send_data csv.export(presenter.wrap(@transactions)), csv_opts
      end
    end
  end

  # GET /regimes/:regime_id/transactions/1
  # GET /regimes/:regime_id/transactions/1.json
  def show
  end

  # GET /regimes/:regimes_id/transactions/1/edit
  def edit
    # @related_transactions = transaction_store.transactions_related_to(@transaction)
  end

  # PATCH/PUT /regimes/:regimes_id/transactions/1
  # PATCH/PUT /regimes/:regimes_id/transactions/1.json
  def update
    respond_to do |format|
      if update_transaction
        format.html { redirect_to edit_regime_transaction_path(@regime, @transaction),
                      notice: 'Transaction was successfully updated.' }
        format.json {
          render json: { transaction: presenter.new(@transaction),
                         message: 'Transaction updated'
                        },
                        status: :ok,
                        location: regime_transaction_path(@regime, @transaction)
        }
      else
        format.html { render :edit }
        format.json { render json: @transaction, status: :unprocessable_entity }
      end
    end
  end

  private
    def csv_opts
      ts = Time.zone.now.strftime("%Y%m%d%H%M%S")
      {
        filename: "transactions_to_be_billed_#{ts}.csv",
        type: :csv
      }
    end

    def update_transaction
      if @transaction.updateable?
        if @transaction.update(transaction_params)
          category_changes = @transaction.previous_changes[:category]
          tc_changes = @transaction.previous_changes[:temporary_cessation]
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

    def present_transactions(transactions, selected_region, regions, summary)
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
      params.require(:transaction_detail).permit(:category, :temporary_cessation)
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end

    def calculator
      @calculator ||= CalculationService.new
    end

    def csv
      @csv ||= TransactionExportService.new(@regime)
    end
end
