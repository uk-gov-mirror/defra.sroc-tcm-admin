class AdminController < ApplicationController
  before_action :admin_only_check!
  
  private
  def admin_only_check!
    redirect_to root_path, notice: 'Only system administrators can access the requested area.' unless current_user && current_user.admin?
  end
end
