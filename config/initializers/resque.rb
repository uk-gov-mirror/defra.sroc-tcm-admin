unless ENV.fetch("HEROKU", false)
  Resque.redis = ENV.fetch("REDIS_URL")
end
