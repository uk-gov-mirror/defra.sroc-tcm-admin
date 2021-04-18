# frozen_string_literal: true

namespace :file_import do
  desc "Check for and process import files"
  task run: :environment do
    FileImportService.call
  end
end
