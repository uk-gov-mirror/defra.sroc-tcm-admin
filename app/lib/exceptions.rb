# frozen_string_literal: true

module Exceptions
  class FileNotFoundError < StandardError; end
  class TransactionFileError < StandardError; end
  class PermissionError < StandardError; end
  class RulesServiceError < StandardError; end

  class ChargingModuleApiError < StandardError
    def initialize(http, endpoint, response)
      super(
        "Failed to connect to Charging Module API. Http = #{http}, endpoint = #{endpoint}, response = #{response}."
      )
    end
  end
end
