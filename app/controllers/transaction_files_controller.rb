# frozen_string_literal: true

class TransactionFilesController < ApplicationController
  include RegimeScope

  before_action :read_only_user_check!

  # POST /regimes/:regime_id/transaction_files
  def create
    set_regime
    set_region
    file = exporter.export
    msg = "Successfully generated transaction file <b>#{file.filename}</b>"
    flash[:success] = msg
    # force page 1 on redirect to prevent possibile invalid page selection
    redirect_to regime_transactions_path(@regime, page: 1)
  end

  private
    # :nocov:
    def set_region
      # TODO: this could be defaulted to a user's region if there are
      # restrictions around this
      @region = params.fetch(:region, '')
    end
    # :nocov:

    def exporter
      @exporter ||= TransactionFileExporter.new(@regime, @region, current_user)
    end
end
