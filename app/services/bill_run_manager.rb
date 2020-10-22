# frozen_string_literal: true

require "net/http"

class BillRunManager < ServiceObject
  attr_reader :regime, :region, :pre_sroc, :bill_run_id

  def initialize(params = {})
    super()
    @regime = params.fetch(:regime)
    @region = params.fetch(:region)
    @pre_sroc = params.fetch(:pre_sroc)
    @bill_run_id = nil
  end

  def call
    @bill_run_id = retrieve_bill_run_id
    @result = @bill_run_id.present?
    self
  rescue StandardError => e
    @result = false
    TcmLogger.notify(e)
    self
  end

  private

  def retrieve_bill_run_id
    # Check the bill runs table for given attributes and return id if one exists
    bill_run = BillRun.find_by(regime: @regime, region: @region, pre_sroc: @pre_sroc)
    return bill_run.bill_run_id unless bill_run.nil?

    # A bill run isn't in the table so query the API to check if one exists
    bill_run_id_from_api = api_get_bill_run

    # If an initialised bill run doesn't exist then create one
    bill_run_id_from_api = api_create_bill_run if bill_run_id_from_api.nil?

    # Store the id we now have in the table
    new_bill_run_entry = BillRun.create(bill_run_id: bill_run_id_from_api,
                                        region: @region,
                                        regime: @regime,
                                        pre_sroc: @pre_sroc)

    # Return the id
    new_bill_run_entry.bill_run_id
  end

  def api_get_bill_run
    list_bill_runs_call = ChargingModule::ListBillRunsService.call(regime: @regime,
                                                                   region: @region,
                                                                   status: "initialised")
    data = list_bill_runs_call.response[:data]
    initialised_pre_sroc_bill_run = data[:billRuns].select { |bill_run| bill_run[:preSroc] == @pre_sroc }

    initialised_pre_sroc_bill_run.first[:id] unless initialised_pre_sroc_bill_run.empty?
  end

  def api_create_bill_run
    # This will need to account for pre-sroc=FALSE when sroc is added
    create_bill_run_call = ChargingModule::CreateBillRunService.call(regime: @regime, region: @region)

    create_bill_run_call.response[:billRun][:id]
  end
end
