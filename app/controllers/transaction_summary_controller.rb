# frozen_string_literal: true

class TransactionSummaryController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index]

  # GET /regimes/:regime_id/transaction_summary
  # GET /regimes/:regime_id/transaction_summary.json
  def index
    @region = params.fetch(:region, '')
    respond_to do |format|
      format.html do
        if request.xhr?
          @summary = Query::TransactionSummary.call(regime: @regime, region: @region)
          @summary.title = "Generate Transaction File"
          render partial: 'shared/summary_dialog', locals: { summary: @summary }
        end
      end
      format.json do
        @summary = transaction_summary.summarize(@region)
        render json: @summary
      end
      format.any do
        head :not_acceptable
      end
    end
  end

  private
    def transaction_summary
      @transaction_summary ||= TransactionSummaryService.new(@regime, current_user)
    end
end
