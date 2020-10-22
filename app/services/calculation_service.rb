# frozen_string_literal: true

require "net/http"

class CalculationService
  attr_reader :user

  def initialize(user = nil)
    @user = user
  end

  def check_connectivity
    # generate a charge to test connectivity
    regime = Regime.find_by!(slug: "cfd")
    parms = {
      permitCategoryRef: regime.permit_categories.first.code,
      percentageAdjustment: "100",
      temporaryCessation: false,
      compliancePerformanceBand: "B",
      billableDays: 365,
      financialDays: 365,
      chargePeriod: "FY1819",
      preConstruction: false,
      environmentFlag: "TEST"
    }

    result = calculate_charge(regime, 2018, parms)
    puts "Successfully generated charge"
    result
  rescue StandardError => e
    msg = "Check connectivity error: #{e.message}"
    TcmLogger.error(msg)
    puts msg
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
    when Net::HTTPSuccess
      # successfully completed charge calculation or
      # an error in the calculation or a ruleset issue
      # we want to show an error at the front end if there's an issue
      JSON.parse(response.body)
    when Net::HTTPInternalServerError
      TcmLogger.error("Calculate charge problem: #{JSON.parse(response.body)}")
      # some kind of server error at the charging service
      build_error_response("Unable to calculate charge due to an unexpected error "\
                           "at the Charge Service.\nPlease try again later")
    else
      # something unexpected happened
      TcmLogger.notify(CalculationServiceError.new(response.value))
      build_error_response("Unable to calculate charge due to an unexpected error."\
                           "\nPlease try again later")
    end
  rescue StandardError => e
    # something REALLY unexpected happened ...
    TcmLogger.notify(e)
    build_error_response("Unable to calculate charge due to the rules service "\
                         "being unavailable. Please log a call with the "\
                         "service desk.")
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
                                  'Content-Type': "application/json")
    request.body = payload.to_json
    request
  end

  def build_error_response(text)
    { "calculation": { "messages": text } }
  end

  def charge_service_url
    @charge_service_url ||= URI.parse(ENV.fetch("CHARGE_SERVICE_URL"))
  end

  def http_connection
    http = Net::HTTP.new(charge_service_url.host, charge_service_url.port)
    http.use_ssl = charge_service_url.scheme.downcase == "https"
    http
  end
end
