# frozen_string_literal: true

module ChargingModule
  class AuthorisationService < ServiceObject

    attr_reader :token

    # The current design of the base service object requires us to provide an
    # initialise method even if we don't need it
    def initialize(_params = {})
      super()
    end

    def call
      @result = true
      @token = oauth2_token
      self
    rescue StandardError
      @result = false
      raise
    end

    private

    def host
      @host ||= ENV.fetch("COGNITO_HOST")
    end

    def username
      @username ||= ENV.fetch("COGNITO_USERNAME")
    end

    def password
      @password ||= ENV.fetch("COGNITO_PASSWORD")
    end

    def oauth2_token
      OAuth2::Client.new(username, password, site: host, token_url: "/oauth2/token")
                    .client_credentials
                    .get_token.token
    end
  end
end
