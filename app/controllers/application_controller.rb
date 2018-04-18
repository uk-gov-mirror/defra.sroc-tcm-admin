class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :cache_buster
  before_action :authenticate_user!

  rescue_from StandardError do |e|
    TcmLogger.notify(e)
    raise e
  end

  protected
  def cache_buster
    # Cache buster, specifically we don't want the client to cache any
    # responses from the service
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate, private"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
