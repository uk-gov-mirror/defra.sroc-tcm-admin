require 'rails_helper'

RSpec.describe Permit, type: :model do
  let :regime { FactoryGirl.create(:regime) }

  describe "attributes" do
    subject { FactoryGirl.create(:permit, regime_id: regime.id) }

    it { is_expected.to validate_presence_of :permit_reference }

    it { is_expected.to validate_presence_of :permit_category }

    it { is_expected.to validate_presence_of :effective_date }

    it { is_expected.to validate_presence_of :status }
  end
end
