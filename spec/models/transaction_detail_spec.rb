require 'rails_helper'

RSpec.describe TransactionDetail, type: :model do
  subject { FactoryGirl.build(:transaction_detail) }

  describe 'validations' do
    it 'is valid with required attributes' do
      expect(subject).to be_valid
    end

    it 'is not valid without a :sequence_number' do
      subject.sequence_number = nil
      expect(subject).to_not be_valid
    end

    it 'is not valid without a :line_amount' do
      subject.line_amount = nil
      expect(subject).to_not be_valid
    end

    it 'is not valid without a :unit_of_measure_price' do
      subject.unit_of_measure_price = nil
      expect(subject).to_not be_valid
    end
  end
end
