# :nocov:
unless ENV.fetch("HEROKU", false)
  Resque.redis = ENV.fetch("REDIS_URL")
  Resque.logger = Logger.new(Rails.root.join('log', "#{Rails.env}_resque.log"))
end
# :nocov:
