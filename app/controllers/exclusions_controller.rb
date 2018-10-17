# frozen_string_literal: true

class ExclusionsController < ApplicationController
  include RegimeScope, CsvExporter, QueryTransactions

  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]

  # GET /regimes/:regime_id/exclusions
  # GET /regimes/:regime_id/exclusions.json
  def index
    @region = params.fetch(:region, cookies.fetch(:region, ''))
    @region = '' if @region == 'all'

    pg = params.fetch(:page, cookies.fetch(:page, 1))
    per_pg = params.fetch(:per_page, cookies.fetch(:per_page, 10))

    @financial_years = Query::FinancialYears.call(regime: @regime)
    @financial_year = params.fetch(:fy, cookies.fetch(:fy, ''))
    @financial_year = '' unless @financial_years.include? @financial_year

    @transactions = Query::ExcludedTransactions.call(query_params)

    respond_to do |format|
      format.html do
        @transactions = present_transactions(@transactions.page(pg).per(per_pg))

        if request.xhr?
          render partial: 'table', locals: { transactions: @transactions }
        else
          render
        end
      end
      format.csv do
        send_data csv.export(presenter.wrap(@transactions.limit(15000))), csv_opts
      end
      format.json do
        render json: present_transactions_for_json(@transactions.page(pg).per(per_pg))
      end
    end
  end

  # GET /regimes/:regime_id/exclusions/1
  # GET /regimes/:regime_id/exclusions/1.json
  def show
  end

  private
    def present_transactions(transactions)
      Kaminari.paginate_array(presenter.wrap(transactions),
                              total_count: transactions.total_count,
                              limit: transactions.limit_value,
                              offset: transactions.offset_value)
    end

    def present_transactions_for_json(transactions)
      regions = Query::Regions.call(regime: @regime)
      selected_region = params.fetch(:region, regions.first)
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
        regions: region_options(regions),
        financial_years: financial_year_options(financial_years)
      }
    end

    def region_options(regions)
      opts = regions.map { |r| { label: r, value: r } }
      opts = [{label: 'All', value: ''}] + opts if opts.count > 1
      opts
    end

    def financial_years
      Query::FinancialYears.call(regime: @regime)
    end

    def financial_year_options(fy_list)
      fys = fy_list.map { |fy| { label: fy[0..1] + '/' + fy[2..3], value: fy } }
      fys = [{label: 'All', value: ''}] + fys if fys.count > 1
      fys
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end
end
