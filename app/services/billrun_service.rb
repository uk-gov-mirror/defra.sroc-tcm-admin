class BillRun < ServiceObject

  def initialize(user = nil)
    @user = user
  end

  def make_payload(regime, financial_year, charge_params)
    {
      regime: regime.slug,
      financialYear: financial_year,
      chargeRequest: charge_params
    }
  end

  def get_bill_run_id(regime, region)
    connection = http_connection
    payload = make_payload(regime, region)
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
  rescue => e
    # something REALLY unexpected happened ...
    TcmLogger.notify(e)
    build_error_response("Unable to calculate charge due to the rules service "\
                         "being unavailable. Please log a call with the "\
                         "service desk.")
  # rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
  #   Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
  #   raise Exceptions::CalculationServiceError.new e
  end

  def build_get_request(regime)
    request = Net::HTTP::Get.new(billrun_url(regime).request_uri,
                                  'Content-Type': 'application/json')
    request.body = payload.to_json
    request
  end

  def billrun_url(regime)
    @billrun_url ||= URI.parse("http://localhost:3040/v1/#{regime}/billruns")
  end

end