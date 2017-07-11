require 'rails_helper'
require 'csv'

RSpec.describe TransactionFileHandler do
  let :record { FactoryGirl.create(:transaction_header, :with_details) }
  let :file_path { Rails.root.join("tmp", "test.csv") }

  describe '#export' do
    it 'creates a file' do
      File.delete(file_path) if File.exist?(file_path)

      subject.export(record, file_path)

      expect(File.exist?(file_path)).to be true
    end

    it 'writes a transaction record to a csv file' do
      File.delete(file_path) if File.exist?(file_path)

      subject.export(record, file_path)

      csv = CSV.read(file_path)

      expect(csv.size).to eq record.transaction_details.count + 2
      expect(csv.first[TransactionFile::Common::RecordType]).to eq "H"
      (1..record.transaction_details.count).each do |n|
        expect(csv[n][TransactionFile::Common::RecordType]).to eq "D"
      end
      expect(csv.last[TransactionFile::Common::RecordType]).to eq "T"
    end
  end

  describe '#import' do
    it 'parses a transaction file into transaction records' do
      File.delete(file_path) if File.exist?(file_path)
      subject.export(record, file_path)
      expect { record.destroy }.to change { TransactionHeader.count }.by -1

      expect { subject.import(file_path) }.to change { TransactionHeader.count }.by 1
    end
  end
end
