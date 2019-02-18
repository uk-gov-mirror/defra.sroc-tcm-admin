# frozen_string_literal: true

class TransactionSummaryController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index]
  before_action :read_only_user_check!

  def index
    @region = params.fetch(:region, '')
    respond_to do |format|
      format.html do
        if request.xhr?
          @summary = Query::TransactionSummary.call(regime: @regime, region: @region)
          @summary.title = "Generate Transaction File"
          @summary.path = regime_transaction_files_path(@regime)
          render partial: 'shared/summary_dialog', locals: { summary: @summary }
        end
      end
    end
  end

  private
    def transaction_summary
      @transaction_summary ||= TransactionSummaryService.new(@regime, current_user)
    end
end
