# frozen_string_literal: true

class RetrospectiveSummaryController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index]

  def index
    @region = params.fetch(:region, '')
    respond_to do |format|
      format.html do
        if request.xhr?
          @summary = PreSrocSummaryQuery.call(regime: @regime, region: @region)
          @summary.title = "Generate Pre-SRoC File"
          render partial: 'shared/summary_dialog', locals: { summary: @summary }
        end
      end
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
