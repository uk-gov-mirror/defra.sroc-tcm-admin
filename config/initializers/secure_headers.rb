SecureHeaders::Configuration.default do |config|
  config.csp_report_only = {
    base_uri: %w('self'),
    default_src: %w('none'),
    font_src: %w('self'),
    form_action: %w('self'),
    frame_ancestors: %w('none'),
    img_src: %w('self'),
    script_src: %w('self'),
    style_src: %w('self')
  }
end
