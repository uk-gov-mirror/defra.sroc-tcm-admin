require "net/http"

class BillRunService
  def get_bill_run_id(regime, region, pre_sroc)
    # Check the bill runs table for given attributes and return id if one exists
    bill_run = BillRun.find_by(regime: regime, region: region, pre_sroc: pre_sroc)
    return bill_run.bill_run_id unless bill_run.nil?

    # A bill run isn't in the table so query the API
    # TODO: account for pre_sroc = false
    bill_run_id_from_api = api_get_bill_run(regime, region)

    # If an initialised bill run doesn't exist then create one
    if bill_run_id_from_api.nil?
      # TODO: account for pre_sroc = false
      bill_run_id_from_api = api_create_bill_run(regime, region)
    end

    # Store the id we now have in the table
    new_bill_run_entry = BillRun.create(bill_run_id: bill_run_id_from_api,
      region: region,
      regime: regime,
      pre_sroc: pre_sroc)

    # Return the id
    return new_bill_run_entry.bill_run_id
  end

  private

  def api_request(connection, request)
    response = connection.request(request)

    case response
    when Net::HTTPSuccess
      return response
    when Net::HTTPInternalServerError
      TcmLogger.error("Bill run service problem: #{JSON.parse(response.body)}")
      build_error_response("Unable to retrieve bill run due to an unexpected error "\
        "at the Charging Module API.\nPlease try again later")
    else
      # something unexpected happened
      TcmLogger.notify(BillRunServiceError.new(response.value))
      build_error_response("Unable to retrieve bill run due to an unexpected error."\
        "\nPlease try again later")
    end
  rescue => e
    # something REALLY unexpected happened ...
    TcmLogger.notify(e)
    build_error_response("Unable to retrieve bill run due to the Charging Module API "\
      "being unavailable. Please log a call with the service desk.")
  end

  def api_get_bill_run(regime, region)
    connection = http_connection(regime)
    response = api_request(connection, build_http_request(Net::HTTP::Get, regime))

    # TODO: Correctly handle error responses

    bill_runs = JSON.parse(response.body)["data"]["billRuns"]
    bill_runs_for_region = bill_runs.select {|bill_run| bill_run["region"] == region}
    initialised_bill_run = bill_runs_for_region.select {|bill_run| bill_run["status"] == "initialised"}
    return initialised_bill_run.first["id"] unless initialised_bill_run.empty?
  end

  def api_create_bill_run(regime, region)
    connection = http_connection(regime)
    response = api_request(connection, build_http_request(Net::HTTP::Post, regime, { region: region }))
  
    # TODO: Correctly handle error response

    created_bill_run = JSON.parse(response.body)
    return created_bill_run["billRun"]["id"]
  end

  def build_http_request(http, regime, payload = '')
    request = http.new(bill_run_url(regime).request_uri,
                                  'Content-Type': 'application/json',
                                  'Authorization': "Bearer #{ENV.fetch('CHARGING_MODULE_AUTH_TOKEN')}")
    request.body = payload.to_json
    request
  end

  def build_error_response(text)
    { "bill run service": { "messages": text }}
  end

  def bill_run_url(regime)
    @bill_run_url ||= URI.parse("#{ENV.fetch('CHARGING_MODULE_API')}/v1/#{regime}/billruns")
  end

  def http_connection(regime)
    http = Net::HTTP.new(bill_run_url(regime).host, bill_run_url(regime).port)
    http.use_ssl = bill_run_url(regime).scheme.downcase == 'https'
    http
  end
end