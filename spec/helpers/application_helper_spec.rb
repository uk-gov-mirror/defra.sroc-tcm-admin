# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#flash_class" do
    context "when level is ':notice" do
      it "returns 'alert-info" do
        expect(helper.flash_class(:notice)).to eq("alert-info")
      end
    end

    context "when level is ':sucess" do
      it "returns 'alert-success" do
        expect(helper.flash_class(:success)).to eq("alert-success")
      end
    end

    context "when level is ':error" do
      it "returns 'alert-danger" do
        expect(helper.flash_class(:error)).to eq("alert-danger")
      end
    end

    context "when level is ':alert" do
      it "returns 'alert-warning" do
        expect(helper.flash_class(:alert)).to eq("alert-warning")
      end
    end
  end
end
