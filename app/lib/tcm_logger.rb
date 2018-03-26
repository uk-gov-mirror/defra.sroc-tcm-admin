module TcmLogger
  def self.notify(exception)
    Airbrake.notify(exception) if defined? Airbrake
    TcmLogger.error(exception.message)
  end

  def self.error(message)
    Rails.logger.error(message)
  end

  def self.warn(message)
    Rails.logger.warn(message)
  end

  def self.info(message)
    Rails.logger.info(message)
  end

  def self.debug(message)
    Rails.logger.debug(message)
  end
end
