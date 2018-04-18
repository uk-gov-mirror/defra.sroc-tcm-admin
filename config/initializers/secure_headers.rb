SecureHeaders::Configuration.default do |config|
  config.csp = {
    base_uri: %w('self'),
    connect_src: %w('self'),
    default_src: %w('none'),
    font_src: %w('self'),
    form_action: %w('self'),
    frame_ancestors: %w('none'),
    img_src: %w('self'),
    script_src: %w('self' 'unsafe-eval'),
    style_src: %w('self' 'unsafe-inline')
  }

  # permit access to webpack devserver
  if Rails.env.development?
    config.csp[:connect_src] << 'localhost:3035'
    config.csp[:connect_src] << 'ws://localhost:3035'
  end
end
