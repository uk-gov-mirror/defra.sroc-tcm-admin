require 'rails_helper'

RSpec.describe Regime, type: :model do
  describe 'attributes' do
    subject { FactoryGirl.create(:regime) }

    it { is_expected.to validate_presence_of :name }

    it { is_expected.to validate_uniqueness_of :name }

    it "returns a parmeterized :name as a URL slug" do
      subject.save!
      expect(subject.reload.to_param).to eq(subject.name.parameterize.downcase)
    end
  end
end
