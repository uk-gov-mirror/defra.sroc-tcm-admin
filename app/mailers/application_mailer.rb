class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('DEVISE_MAILER_SENDER')
  layout 'mailer'

  def prevent_tracking
    headers({
      "X-SMTPAPI" => {
        "filters" => {
          "bypass_list_management" => {
            "settings" => {
              "enable" => 1
            }
          },
          "clicktrack" => {
            "settings" => {
              "enable" => 0
            }
          }
        }
      }.to_json
    })
  end
end
