require 'rails_helper'

RSpec.describe Regime, type: :model do
  subject { FactoryGirl.build(:regime) }

  describe 'validations' do
    it 'is valid with required attributes' do
      expect(subject).to be_valid
    end

    it 'is not valid without a name' do
      subject.name = nil
      expect(subject).to_not be_valid
    end
  end
end
