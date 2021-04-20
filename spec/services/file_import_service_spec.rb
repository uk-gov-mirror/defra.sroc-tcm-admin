# frozen_string_literal: true

require "rails_helper"

RSpec.describe FileImportService do
  describe "#call" do
    let(:import_file) { "cfdti999.dat.csv" }
    let(:service) { FileImportService.new }
    let(:etl_file_store) { LocalFileStore.new("etl_bucket") }
    let(:archive_file_store) { LocalFileStore.new("archive_bucket") }

    before(:each) do
      # Copy our import fixture to the import folder. It doesn't matter if it already exists as we just overwrite
      etl_file_store.store_file(Rails.root.join("spec", "fixtures", import_file), File.join("import", import_file))

      # The file importer uses `puts()` to ensure details are logged when run from a rake task. We don't want that
      # output in our tests so we use this to silence it. If you need to debug anything whilst working on tests
      # for it just comment out this line temporarily
      allow($stdout).to receive(:puts)
    end

    after(:each) do
      # Clean up - ensure any files we create irrespective of whether the test is successful or not is deleted
      full_path = File.join(etl_file_store.base_path, "import", import_file)
      FileUtils.rm(full_path) if File.exist?(full_path)

      full_path = File.join(archive_file_store.base_path, "import", import_file)
      FileUtils.rm(full_path) if File.exist?(full_path)

      full_path = File.join(archive_file_store.base_path, "quarantine", import_file)
      FileUtils.rm(full_path) if File.exist?(full_path)
    end

    context "when no other import is running" do
      let(:user) { build(:user) }
      let!(:regime) { create(:regime) }

      before(:each) do
        allow_any_instance_of(SystemConfig).to receive(:start_import).and_return(true)
        allow(User).to receive(:system_account).and_return(user)
      end

      it "deletes the original import file" do
        service.call

        expect(etl_file_store.list("import")).not_to include("import/#{import_file}")
      end

      it "creates a copy in the 'archive_bucket'" do
        service.call

        expect(archive_file_store.list("import")).to include("import/#{import_file}")
      end

      it "imports the transaction data" do
        service.call

        transaction_header = TransactionHeader.first
        transaction_details = TransactionDetail.all

        expect(transaction_header.filename).to eq(import_file)
        expect(transaction_header.file_reference).to eq("CFDTI00999")
        expect(transaction_details.length).to eq(3)
      end
    end

    context "when another import is running" do
      before(:each) do
        allow_any_instance_of(SystemConfig).to receive(:start_import).and_return(false)
      end

      it "doesn't attempt to import any files" do
        service.call

        expect(etl_file_store.list("import")).to include("import/#{import_file}")
      end
    end
  end

end
