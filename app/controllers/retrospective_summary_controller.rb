# frozen_string_literal: true

class RetrospectiveSummaryController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index]

  def index
    respond_to do |format|
      format.js
      format.json do
        region = params.fetch(:region, '')
        @summary = transaction_summary.summarize_retrospectives(region)
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
