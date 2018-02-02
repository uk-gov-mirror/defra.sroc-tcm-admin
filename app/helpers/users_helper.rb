module UsersHelper
  def user_submit_button(form)
    title = action_name == 'edit' ? 'Update User' : 'Add and Invite User'
    form.submit(title, class: 'btn btn-primary')
  end

  def role_label(name)
    if name == 'billing'
      'Billing Admin'
    elsif name == 'admin'
      'System Admin'
    else
      raise ArgumentError, "Unknown role '#{name}'"
    end
  end
end
