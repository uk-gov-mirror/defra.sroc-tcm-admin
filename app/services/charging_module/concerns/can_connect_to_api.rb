# frozen_string_literal: true

module ChargingModule
  module CanConnectToApi
    extend ActiveSupport::Concern

    private

    def make_get_request(endpoint, params = {})
      make_request(Net::HTTP::Get, endpoint, nil, params)
    end

    def make_post_request(endpoint, payload = {})
      make_request(Net::HTTP::Post, endpoint, payload, nil)
    end

    def make_request(http, endpoint, payload, params)
      request = build_http_request(endpoint, payload, params, http)
      response = send_request(request)
      handle_request_response(endpoint, http, response)
    end

    def build_http_request(endpoint, payload, params, http)
      request = http.new(
        build_uri(endpoint, params),
        'Content-Type': 'application/json',
        'Authorization': auth_token
      )
      request.body = payload.to_json

      request
    end

    def build_uri(endpoint, params)
      uri = URI("#{url}/#{endpoint}")
      uri.query = URI.encode_www_form(params) if params.present?

      uri
    end

    def send_request(request)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme.downcase == 'https'

      http.request(request)
    end

    def handle_request_response(endpoint, http, response)
      return successful_request(response.body) if response.is_a? Net::HTTPSuccess

      raise Exceptions::ChargingModuleApiError.new(http, endpoint, response)
    end

    def successful_request(body)
      JSON.parse(body, symbolize_names: true)
    end

    def url
      @url ||= URI.parse(ENV.fetch('CHARGING_MODULE_API'))
    end

    def auth_token
      @auth_token ||= AuthorisationService.call.token
    end
  end
end
