module UsersHelper
  def user_submit_button(form)
    title = form.object.new_record? ? 'Add and Invite User' : 'Update User'
    form.submit(title, class: 'btn btn-primary')
  end

  def role_label(name)
    name = name.to_s
    if name == 'billing'
      'Billing Admin'
    elsif name == 'admin'
      'System Admin'
    elsif name == 'read_only'
      'Read-only User'
    elsif name == 'read_only_export'
      'Read-only + Export'
    else
      raise ArgumentError, "Unknown role '#{name}'"
    end
  end

  def regime_names(user)
    user.regimes.map { |r| r.title }.join(', ')
  end
end
