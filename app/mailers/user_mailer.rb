#frozen_string_literal: true
class UserMailer < ApplicationMailer
  def invitation(email, name, invitation_link)
    @email = email
    @name = name
    @invitation_link = invitation_link
    prevent_tracking
    mail(to: email, subject: 'Account created - SRoC Tactical Charging Module')
  end
end
