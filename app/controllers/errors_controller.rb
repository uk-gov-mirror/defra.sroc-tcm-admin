# frozen_string_literal: true
class ErrorsController < ActionController::Base

  def show
    @exception = request.env["action_dispatch.exception"]
    @status_code = ActionDispatch::ExceptionWrapper.new(request.env, @exception).status_code

#  action = request.path[1..-1].gsub(/[^0-9]/, "")
    # action = 500 if action.blank?

    # status_code =
    #   if @exception
    #     trace = Rails.backtrace_cleaner.clean(@exception.backtrace)
    #     Rails.logger.fatal trace.join("#\n")
    #
    #     ActionDispatch::ExceptionWrapper.new(env, @exception).status_code
    #   else
    #     action.to_i
    #   end

    respond_to do |format|
      format.html { render action: @status_code.to_s, status: @status_code, layout: 'error' }
      format.json { render json: { status: @status_code, error: @exception.message } }
    end
  end
end
