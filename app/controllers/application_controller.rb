class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  # http_basic_authenticate_with name: ENV.fetch('AUTH_NAME'), password: ENV.fetch('AUTH_PWD') if ENV.fetch('HEROKU', false)
end
