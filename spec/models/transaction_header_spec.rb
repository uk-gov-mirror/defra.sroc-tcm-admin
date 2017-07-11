require 'rails_helper'

RSpec.describe TransactionHeader, type: :model do
  subject { FactoryGirl.build(:transaction_header) }

  describe 'validations' do
    it 'is valid with required attributes' do
      expect(subject).to be_valid
    end

    it 'is not valid without a :feeder_source_code' do
      subject.feeder_source_code = nil
      expect(subject).to_not be_valid
    end

    it 'is not valid without a :region' do
      subject.region = nil
      expect(subject).to_not be_valid
    end

    it 'is not valid without a :file_sequence_number' do
      subject.file_sequence_number = nil
      expect(subject).to_not be_valid
    end

    it 'is not valid without a :generated_at date' do
      subject.generated_at = nil
      expect(subject).to_not be_valid
    end
  end
end
