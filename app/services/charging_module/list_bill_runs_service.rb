# frozen_string_literal: true

require_relative "concerns/can_connect_to_api"

module ChargingModule
  class ListBillRunsService < ServiceObject
    include ChargingModule::CanConnectToApi

    attr_reader :response

    def initialize(params = {})
      regime = params.fetch(:regime)
      @endpoint = "#{regime}/billruns"
    end

    def call
      @response = make_get_request(@endpoint)
      @result = true

      self
    rescue StandardError => e
      @result = false
      TcmLogger.notify(e)

      self
    end
  end
end
