class CalculateCharge < ServiceObject
  include RegimeScope

  def initialize(params = {})
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

  private

  def extract_charge_amount
    if success?
      amt = (@body["calculation"]["chargeValue"] * 100).round
      amt = -amt if @transaction.credit?
      amt
    end
  end

  def calculate_charge
    @response = http_connection.request(build_post_request)

    case @response
    when Net::HTTPSuccess
      # successfully completed charge calculation or
      # an error in the calculation or a ruleset issue
      # we want to show an error at the front end if there's an issue
      @body = JSON.parse(@response.body)
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
      TcmLogger.notify(CalculationServiceError.new(@response.value))
      @body = build_error_response("Unable to calculate charge due to an " \
                                   "unexpected error.\nPlease try again later")
      false
    end
  rescue => e
    # something REALLY unexpected happened ...
    TcmLogger.notify(e)
    @body = build_error_response("Unable to calculate charge due to the rules " \
                                 "service being unavailable. Please log a call " \
                                 "with the service desk.")
    false
  # rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
  #   Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
  #   raise Exceptions::CalculationServiceError.new e
  end

  def payload
    {
      regime: @regime.slug,
      financialYear: @financial_year,
      chargeRequest: @charge_params
    }
  end

  def build_post_request
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
