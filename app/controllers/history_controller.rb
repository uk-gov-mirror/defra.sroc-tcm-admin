# frozen_string_literal: true

class HistoryController < ApplicationController
  include RegimeScope, CsvExporter, QueryTransactions

  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]

  # GET /regimes/:regime_id/history
  # GET /regimes/:regime_id/history.json
  def index
    @region = params.fetch(:region, cookies.fetch(:region, ''))

    pg = params.fetch(:page, cookies.fetch(:page, 1))
    per_pg = params.fetch(:per_page, cookies.fetch(:per_page, 10))
    
    @financial_years = Query::FinancialYears.call(regime: @regime)
    @financial_year = params.fetch(:fy, cookies.fetch(:fy, ''))
    @financial_year = '' unless @financial_years.include? @financial_year

    @transactions = Query::BilledTransactions.call(query_params)

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
    end
  end

  # GET /regimes/:regime_id/history/1
  # GET /regimes/:regime_id/history/1.json
  def show
  end

  private
    def present_transactions(transactions)
      Kaminari.paginate_array(presenter.wrap(transactions, current_user),
                              total_count: transactions.total_count,
                              limit: transactions.limit_value,
                              offset: transactions.offset_value)
    end
end
