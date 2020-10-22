# frozen_string_literal: true

module ViewModels
  class AuditDetail
    attr_accessor :action, :attribute, :old_value, :new_value, :when, :who

    def description
      case action
      when "modify"
        if old_value.nil?
          # setting a value
          if charge_calculation_error?(new_value)
            I18n.t("error_html", scope: audit_scope, message: new_attr_value)
          else
            I18n.t("added_html", scope: audit_scope, value: new_attr_value)
          end
        elsif new_value.nil?
          # removing a value
          I18n.t("removed_html", scope: audit_scope, value: old_attr_value)
        else
          # changing a value
          old_err = charge_calculation_error?(old_value)
          new_err = charge_calculation_error?(new_value)

          if old_err && new_err
            I18n.t("error_html",
                   scope: audit_scope,
                   message: new_attr_value)
          elsif old_err
            I18n.t("error_old_html",
                   scope: audit_scope,
                   value: new_attr_value)
          elsif new_err
            I18n.t("error_new_html",
                   scope: audit_scope,
                   old_value: old_attr_value,
                   message: new_attr_value)
          else
            I18n.t("changed_html",
                   scope: audit_scope,
                   old_value: old_attr_value,
                   new_value: new_attr_value)
          end
        end
      when "suggestion"
        I18n.t("suggested_html", scope: audit_scope, value: new_attr_value)
      when "create"
        I18n.t("audit.create_html", file: new_attr_value)
      when "export"
        I18n.t("audit.export_html", file: new_attr_value)
      end.html_safe
    end

    def occurred_at
      self.when.strftime("%d/%m/%y %H:%M:%S")
    end

    def instigated_by
      who.full_name
    end

    private

    def old_attr_value
      describe_value(old_value)
    end

    def new_attr_value
      describe_value(new_value)
    end

    def charge_calculation_error?(val)
      @attribute == "charge_calculation" &&
        val["calculation"] && val["calculation"]["messages"]
    end

    def audit_scope
      @audit_scope ||= "audit.#{@attribute}"
    end

    def describe_value(value)
      case @attribute
      when "charge_calculation"
        extract_calculation(value)
      when "tcm_charge"
        ActiveSupport::NumberHelper.number_to_currency(
          format("%<value>.2f", value: (value / 100.0)), unit: "£"
        )
      when "approved_for_billing"
        value ? "approved" : "unapproved"
      when "excluded"
        value ? "excluded" : "included"
      when "temporary_cessation"
        value ? "Yes" : "No"
      else
        value
      end
    end

    def extract_calculation(val)
      calc = val["calculation"]
      if calc
        if calc["chargeValue"]
          calc["chargeValue"]
        elsif calc["messages"]
          calc["messages"]
        else
          "Unknown"
        end
      else
        "Unknown"
      end
    end
  end
end
