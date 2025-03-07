# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  config.web_console.whitelisted_ips = "10.0.0.0/8"

  # recompile webpack files as we make changes
  config.x.webpacker[:dev_server_host]

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Sending e-mails is required for confirmation emails
  config.action_mailer.default_url_options = {
    host: ENV.fetch("DEFAULT_URL_HOST", "http://localhost:3000"),
    protocol: "http"
  }

  # Don't care if the mailer can't send (if set to false)
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp

  # Default settings are for mailcatcher
  config.action_mailer.smtp_settings = {
    user_name: ENV.fetch("EMAIL_USERNAME", ""),
    password: ENV.fetch("EMAIL_PASSWORD", ""),
    domain: ENV.fetch("DEFAULT_URL_HOST", "http://localhost:3000"),
    address: ENV.fetch("EMAIL_HOST", "localhost"),
    port: ENV.fetch("EMAIL_PORT", 1025),
    authentication: :plain,
    enable_starttls_auto: true
  }

  # Use a real queuing backend for Active Job (and separate queues per environment)
  config.active_job.queue_adapter     = :resque
  config.active_job.queue_name_prefix = "sroc-tcm-admin_#{Rails.env}"

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
