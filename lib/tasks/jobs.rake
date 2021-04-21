# frozen_string_literal: true

namespace :jobs do
  desc "Check for and process transaction import files"
  task file_import: :environment do
    FileImportService.call
  end
end
