class FileCheckJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Look to see whether there are any files that need processing
    service = FileStorageService.new
    files = service.list_files_in(:import)
    return unless files.count.positive?

    success = 0
    failed = 0

    files.each do |f|
      begin
        tmpfile = Tempfile.new
        service.fetch_file_from(:import, f, tmpfile.path)
        tmpfile.rewind
        service.store_file_in(:export, tmpfile.path, f)
        service.delete_file_from(:import, f)
        success += 1
      rescue => e
        Rails.logger.info("Failed to copy file: #{e}")
        failed += 1
      ensure
        tmpfile.close
        tmpfile.unlink
      end
    end

    Rails.logger.info("Successfully copied #{success} files, failed to copy #{failed}")
  end
end
