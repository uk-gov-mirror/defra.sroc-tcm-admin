# frozen_string_literal: true

SecureHeaders::Configuration.default do |config|
  # We have to use single quotes here, even though it's against style - double doesn't work
  # rubocop:disable Lint/PercentStringArray
  config.csp = {
    base_uri: %w['self'],
    connect_src: %w['self' https://www.google-analytics.com],
    default_src: %w['none'],
    font_src: %w['self'],
    form_action: %w['self'],
    frame_ancestors: %w['none'],
    img_src: %w['self' data:],
    script_src: %w['self' 'unsafe-eval' 'unsafe-inline' www.googletagmanager.com www.google-analytics.com],
    style_src: %w['self' 'unsafe-inline']
  }
  # rubocop:enable Lint/PercentStringArray

  # permit access to webpack devserver
  # if Rails.env.development?
  #   config.csp[:connect_src] << 'localhost:3035'
  #   config.csp[:connect_src] << 'ws://localhost:3035'
  # end
end
