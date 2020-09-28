# frozen_string_literal: true

require_relative 'concerns/can_connect_to_api'

module ChargingModule
  class CreateBillRunService < ServiceObject
    include ChargingModule::CanConnectToApi

    attr_reader :response

    def initialize(payload = {})
      regime = payload.fetch(:regime)
      @endpoint = "#{regime}/billruns"
      @payload = payload.except(:regime)
    end

    def call
      @response = make_post_request(@endpoint, @payload)
      @result = true

      self
    rescue StandardError => e
      @result = false
      TcmLogger.notify(e)

      self
    end
  end
end
