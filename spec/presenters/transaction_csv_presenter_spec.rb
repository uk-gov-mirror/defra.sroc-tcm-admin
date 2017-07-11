require 'rails_helper'

RSpec.describe TransactionCsvPresenter do
  subject do
    described_class.new(FactoryGirl.create(:transaction_header, :with_details))
  end

  describe '#header' do
    let :header { subject.header }

    it 'returns an array of values for the file header' do
      expect(header).to match_array header_data(subject)
    end

    it 'sets the record type as "H"' do
      expect(header[TransactionFile::Common::RecordType]).to eq "H"
    end

    it 'sets :sequence_number to 7 zeroes' do
      expect(header[TransactionFile::Common::SequenceNumber]).to eq "0000000"
    end

    it 'formats :generated_at in the style 1-JAN-2017' do
      expect(header[TransactionFile::Header::FileDate]).to eq subject.generated_at.strftime("%-d-%^b-%Y")
    end

    context 'when regime is "CFD"' do
      it 'does not zero pad :file_sequence_number' do
        t = FactoryGirl.create(:transaction_header, :with_details, feeder_source_code: "CFD")
        tp = described_class.new(t)
        expect(tp.header[TransactionFile::Header::FileSequenceNumber]).to eq t.file_sequence_number
      end
    end

    context 'when regime is not "CFD"' do
      it 'zero pads :file_sequence_number to 5 digits' do
        expect(header[TransactionFile::Header::FileSequenceNumber]).to match /\d{5}/
      end
    end
  end

  describe '#details' do
    let :details { subject.details }

    it 'returns an array of arrays containing detail values' do
      expect(details.count).to eq 3
    end

    it 'sets the record type as "D"' do
      details.each do |detail|
        expect(detail[TransactionFile::Common::RecordType]).to eq "D"
      end
    end

    it 'zero pads :sequence_number to 7 digits' do
      details.each do |detail|
        expect(detail[TransactionFile::Common::SequenceNumber]).to match /\d{7}/
      end
    end

    it 'sets the first detail record :sequence_number to 1' do
      expect(details.first[TransactionFile::Common::SequenceNumber].to_i).to eq 1
    end

    it 'formats :transaction_date in the style 1-JAN-2017' do
      details.each do |detail|
        expect(detail[TransactionFile::Detail::TransactionDate]).to match /\d{1,2}-[A-Z]{3}-\d{4}/
      end
    end

    it 'zero pads :line_amount to 3 digits' do
      details.each do |detail|
        expect(detail[TransactionFile::Detail::LineAmount]).to match /\d{3}/
      end
    end

    it 'zero pads :unit_of_measure_price to 3 digits' do
      details.each do |detail|
        expect(detail[TransactionFile::Detail::LineUOMPrice]).to match /\d{3}/
      end
    end

    it 'ensures :line_amount and :unit_of_measure_price are equal' do
      details.each do |detail|
        line_amount = detail[TransactionFile::Detail::LineAmount]
        uom_price = detail[TransactionFile::Detail::LineUOMPrice]
        expect(line_amount).to eq uom_price
      end
    end
  end

  describe '#trailer' do
    let :trailer { subject.trailer }

    it 'returns an array of values for the file trailer' do
      expect(trailer).to match_array trailer_data(subject)
    end

    it 'sets the :record_type as "T"' do
      expect(trailer[TransactionFile::Common::RecordType]).to eq "T"
    end

    it 'sets the :sequence_number to the next record in the file' do
      recs = trailer[TransactionFile::Common::SequenceNumber].to_i
      expect(recs).to eq subject.transaction_details.count + 1
    end

    it 'zero pads :sequence_number to 7 digits' do
      expect(trailer[TransactionFile::Common::SequenceNumber]).to match /\d{7}/
    end

    it 'sets :record_count to be the sum of the header, detail and trailer records' do
      count = subject.transaction_details.count + 2
      rec_count = trailer[TransactionFile::Trailer::RecordCount].to_i

      expect(rec_count).to eq count
    end

    it 'zero pads :record_count to 8 digits' do
      expect(trailer[TransactionFile::Trailer::RecordCount]).to match /\d{8}/
    end
  end

  def header_data(t)
    [
      "H",
      "0000000",
      t.feeder_source_code,
      t.region,
      "I",
      t.file_sequence_number.to_s.rjust(5, "0"),
      t.bill_run_id,
      t.generated_at.strftime("%-d-%^b-%Y")
    ]
  end

  def trailer_data(t)
    count = t.transaction_details.count
    [
      "T",
      (count + 1).to_s.rjust(7, "0"),
      (count + 2).to_s.rjust(8, "0"),
      t.invoice_total,
      t.credit_total
    ]
  end
end
