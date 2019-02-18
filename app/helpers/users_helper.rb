module UsersHelper
  def user_submit_button(form)
    title = form.object.new_record? ? 'Add and Invite User' : 'Update User'
    form.submit(title, class: 'btn btn-primary')
  end

  def role_label(name)
    t(name.to_s, scope: 'user.roles')
  end

  def regime_names(user)
    user.regimes.map { |r| r.title }.join(', ')
  end
end
