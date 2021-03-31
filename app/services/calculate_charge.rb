# frozen_string_literal: true

require "net/http"

class CalculateCharge < ServiceObject
  include RegimeScope

  def initialize(params = {})
    super()
    @transaction = params.fetch(:transaction)
    @regime = @transaction.regime
    # this needs to  be decorated by a presenter to provide charge params etc
    transaction = presenter.new(@transaction)
    @charge_params = transaction.charge_params
    @financial_year = transaction.financial_year

    @result = @body = @full_response = @amount = nil
  end

  def call
    @result = calculate_charge
    self
  end

  def success?
    @result
  end

  def failure?
    !@result
  end

  def charge_calculation
    @body
  end

  def amount
    @amount ||= extract_charge_amount
  end

  def self.test_connection
    regime = Regime.find_by!(slug: "cfd")
    transaction_detail = TransactionDetail.new(
      regime: regime,
      category: "2.3.1",
      temporary_cessation: false,
      period_start: Date.new(2018, 4, 1),
      period_end: Date.new(2019, 3, 31),
      tcm_financial_year: "1819"
    )

    CalculateCharge.new(transaction: transaction_detail).call
  end

  private

  def calculate_charge
    @url = build_url
    request = build_request
    @response = http_connection.request(request)

    case @response
    when Net::HTTPSuccess
      # successfully completed charge calculation or
      # an error in the calculation or a ruleset issue
      # we want to show an error at the front end if there's an issue
      @body = build_response(JSON.parse(@response.body))
      true
    when Net::HTTPInternalServerError
      TcmLogger.error("Calculate charge problem: #{JSON.parse(@response.body)}")
      # some kind of server error at the charging service
      @body = build_error_response("Unable to calculate charge due to an " \
                                   "unexpected error at the Charge Service.\n" \
                                   "Please try again later")
      false
    else
      # something unexpected happened
      TcmLogger.notify(RulesServiceError.new(@response.value))
      @body = build_error_response("Unable to calculate charge due to an " \
                                   "unexpected error.\nPlease try again later")
      false
    end
  rescue StandardError => e
    # something REALLY unexpected happened ...
    TcmLogger.notify(e)
    @body = build_error_response("Unable to calculate charge due to the rules " \
                                 "service being unavailable. Please log a call " \
                                 "with the service desk.")
    false
  end

  def build_url
    URI.parse(File.join(ENV.fetch("RULES_SERVICE_URL"), determine_path))
  end

  def determine_path
    env_slug = @regime.slug.upcase.squish
    year_suffix = "_#{@financial_year}_#{(@financial_year + 1).to_s[-2..3]}"

    path = File.join(ENV.fetch("#{env_slug}_APP"), ENV.fetch("#{env_slug}_RULESET"))

    "#{path}#{year_suffix}"
  end

  def build_request
    request = Net::HTTP::Post.new(@url.request_uri, 'Content-Type': "application/json")
    request.body = { tcmChargingRequest: @charge_params }.to_json
    request.basic_auth(ENV.fetch("RULES_SERVICE_USER"), ENV.fetch("RULES_SERVICE_PASSWORD"))

    request
  end

  def http_connection
    http = Net::HTTP.new(@url.host, @url.port)
    http.use_ssl = @url.scheme.downcase == "https"

    http
  end

  def build_response(body)
    response = {
      uuid: body["__DecisionID__"],
      generatedAt: Time.new,
      calculation: body["tcmChargingResponse"]
    }

    response.with_indifferent_access
  end

  def build_error_response(text)
    { "calculation": { "messages": text } }
  end

  def extract_charge_amount
    return unless success?

    amt = (charge_calculation["calculation"]["chargeValue"] * 100).round
    amt = -amt if @transaction.credit?
    amt
  end
end
