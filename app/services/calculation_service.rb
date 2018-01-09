require "net/http"

class CalculationService
  attr_reader :user

  def initialize(user = nil)
    @user = user
  end

  def calculate_transaction_charge(transaction)
    regime = transaction.regime
    financial_year = transaction.financial_year
    charge_params = transaction.charge_params

    calculate_charge(regime, financial_year, charge_params)
  end

  def calculate_charge(regime, financial_year, charge_params)
    connection = http_connection
    payload = make_payload(regime, financial_year, charge_params)
    response = connection.request(build_post_request(payload))

    case response
    when Net::HTTPSuccess, Net::HTTPInternalServerError
      # successfully completed charge calculation or
      # an error in the calculation or a ruleset issue
      # we want to show an error at the front end if there's an issue
      JSON.parse(response.body)
    else
      # something unexpected happened
      build_error_response(response.value)
      # raise Exceptions::CalculationServiceError.new(response.value)
    end
  rescue => e
    # something REALLY unexpected happened ...
    # raise Exceptions::CalculationServiceError.new(e)
    build_error_response(e.message)
  # rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
  #   Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
  #   raise Exceptions::CalculationServiceError.new e
  end

private
  def make_payload(regime, financial_year, charge_params)
    {
      regime: regime.slug,
      financialYear: financial_year,
      chargeRequest: charge_params
    }
  end

  def build_post_request(payload)
    request = Net::HTTP::Post.new(charge_service_url.request_uri,
                                  'Content-Type': 'application/json')
    request.body = payload.to_json
    request
  end

  def build_error_response(text)
    { "calculation": { "messages": text }}
  end

  def charge_service_url
    @charge_service_url ||= URI.parse(ENV.fetch('CHARGE_SERVICE_URL'))
  end

  def http_connection
    http = Net::HTTP.new(charge_service_url.host, charge_service_url.port)
    http.use_ssl = charge_service_url.scheme.downcase == 'https'
    http
  end
end
