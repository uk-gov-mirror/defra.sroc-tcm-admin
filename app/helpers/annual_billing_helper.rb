module AnnualBillingHelper
  include AnnualBillingDataFileFormat

  def annual_billing_csv_column_descriptions_for(regime)
    items = [ "<dl class='row'>" ]
    send("#{regime.to_param}_columns").each do |c|
      items << "<dt class='col-sm-4 col-md-3'>#{c[:header].to_s.humanize.titlecase}</dt>"
      items << "<dd class='col-sm-7 col-md-8'>#{Descriptions[c[:header]]}</dd>"
    end
    items << '</dl>'
    items.join.html_safe
  end
end
