module FormErrorHelper
  def error_header(resource, opts = {})
    if resource.errors.any?
      default_opts = {
        resource: resource,
        title: "Check your details",
        description: "The following #{"error".pluralize(resource.errors.count)} prevented the form from being saved:"
      }
      render partial: 'shared/error_header', locals: opts.reverse_merge(default_opts)
    end
  end

  def error_list(resource)
    el = []
    resource.errors.keys.sort.each do |k|
      resource.errors.full_messages_for(k).each do |message|
        el << error_item(k, message)
      end
    end
    content_tag(:ul, class: "error-summary-list list-unstyled") do
      safe_join(el, "\n")
    end
  end

  def error_group(resource, attr, html_opts = {}, &block)
    message = nil

    if resource.errors.include?(attr.to_sym)
      # there are errors for this attribute
      html_class = html_opts.fetch(:class, '')
      html_class += " #{error_class(resource, attr)}"
      html_opts.merge!(class: html_class)
      el = []
      resource.errors.full_messages_for(attr).each do |message|
        el << error_trim(message)
      end
      message = content_tag(:div, class: "error-item") do
        safe_join(el, "\n")
      end
    end
    content = []
    content << capture(&block) if block_given?
    content << message unless message.nil?

    content_tag(:div, html_opts) do
      safe_join(content)
    end
  end

  def error_class(resource, id)
    if resource.errors.any? && resource.errors.include?(id.to_sym)
      "form-error error-#{id}"
    end
  end

  # This enables us to have custom messages without the attribute name
  # at the beginning.
  # When adding a message in a validator do this:
  # errors.add(:my_attr, "^You must do something")
  # When outputting the errors.full_messages / full_messages_for(:attr)
  # pipe it through here to trim off everything upto and including the '^'
  # or just return the original message if no '^' is present
  def error_trim(message)
    message.split("^").last if message
  end

  def error_item(attr, message)
    content_tag(:li, error_trim(message))
  end
end
