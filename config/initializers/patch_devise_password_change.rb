# frozen_string_literal: true

# This overrides the #update_with_password method from:
# devise/lib/devise/models/database_authenticatable.rb
#
# The default change password stuff in Devise caters for updating other user params
# and allows a blank password to allow for if the user didn't want to change their
# password.
# We *only* want it to change the password and having a blank password is not
# permitted. Note: Devise doesn't actually set a blank password, it just ignores the
# change but we want to inform the user that a new password is required.
module Devise
  module Models
    module DatabaseAuthenticatable
      def update_with_password(params, *options)
        current_password = params.delete(:current_password)

        result = if valid_password?(current_password)
          update(params, *options)
        else
          self.assign_attributes(params, *options)
          self.valid?
          self.errors.add(:current_password, current_password.blank? ? :blank : :invalid)
          false
        end

        clean_up_passwords
        result
      end
    end
  end
end
