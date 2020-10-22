# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :admin_only_check!

  private

  NOTICE = "Only system administrators can access the requested area."

  def admin_only_check!
    redirect_to root_path, notice: NOTICE unless current_user&.admin?
  end
end
