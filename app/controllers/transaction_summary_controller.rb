# frozen_string_literal: true

class TransactionSummaryController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index]

  # GET /regimes/:regime_id/transaction_summary
  # GET /regimes/:regime_id/transaction_summary.json
  def index
    respond_to do |format|
      format.js
      format.json do
        region = params.fetch(:region, '')
        @summary = transaction_summary.summarize(region)
        render json: @summary
      end
      format.any do
        head :not_acceptable
      end
    end
  end

  private
    def transaction_summary
      @transaction_summary ||= TransactionSummaryService.new(@regime)
    end
end
