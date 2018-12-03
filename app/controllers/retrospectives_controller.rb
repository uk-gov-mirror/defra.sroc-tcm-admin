# frozen_string_literal: true

class RetrospectivesController < ApplicationController
  include RegimeScope, CsvExporter, QueryTransactions, ViewModelBuilder

  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]
  before_action :redirect_if_waste

  # GET /regimes/:regime_id/history
  # GET /regimes/:regime_id/history.json
  def index
    @view_model = build_retrospectives_view_model

    # @region = params.fetch(:region, cookies.fetch(:region, ''))
    # @region = '' if @region == 'all'
    #
    # pg = params.fetch(:page, 1)
    # per_pg = params.fetch(:per_page, 10)
    #
    # @financial_years = Query::FinancialYears.call(regime: @regime)
    # @financial_year = params.fetch(:fy, cookies.fetch(:fy, ''))
    # @financial_year = '' unless @financial_years.include? @financial_year
    #
    # @transactions = Query::PreSrocTransactions.call(query_params)
    #
    # summary = nil

    respond_to do |format|
      format.html do
        # @transactions = present_transactions(@transactions.page(pg).per(per_pg))
        if request.xhr?
          render partial: 'table', locals: { view_model: @view_model }
        else
          render
        end
      end
      format.csv do
        send_data csv.export(@view_model.csv_transactions), csv_opts
        # send_data csv.export(presenter.wrap(@transactions.limit(15000))), csv_opts
      end
      # format.json do
      #   @transactions = present_transactions_for_json(@transactions, @region, regions)
      #   render json: @transactions
      # end
    end
  end

  # GET /regimes/:regime_id/history/1
  # GET /regimes/:regime_id/history/1.json
  def show
  end

  private
    def redirect_if_waste
      redirect_to regime_transactions_path(@regime) if @regime.waste?
    end

    def present_transactions(transactions)
      Kaminari.paginate_array(presenter.wrap(transactions, current_user),
                              total_count: transactions.total_count,
                              limit: transactions.limit_value,
                              offset: transactions.offset_value)
    end

    def present_transactions_for_json(transactions, selected_region, regions)
      arr = present_transactions(transactions)
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

    def financial_year_options(fy_list)
      fys = fy_list.map { |fy| { label: fy[0..1] + '/' + fy[2..3], value: fy } }
      fys = [{label: 'All', value: ''}] + fys if fys.count > 1
      fys
    end

    # def transaction_store
    #   @transaction_store ||= TransactionStorageService.new(@regime, current_user)
    # end
end
