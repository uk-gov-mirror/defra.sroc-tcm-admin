# frozen_string_literal: true

class FileImportService < ServiceObject
  def initialize(_params = {})
    super()
  end

  def call
    return unless SystemConfig.config.start_import

    begin
      # Look to see whether there are any files that need processing
      user = User.system_account
      Thread.current[:current_user] = user
      importer = TransactionFileImporter.new

      success = 0
      failed = 0
      quarantined = 0

      result = ListEtlImportFiles.call
      result.files.each do |f|
        begin
          in_file = Tempfile.new
          out_file = Tempfile.new
          GetEtlImportFile.call(remote_path: f, local_path: in_file.path)
          in_file.rewind

          transaction_file = importer.import(in_file.path, File.basename(f))
          if transaction_file&.valid?
            in_file.rewind
            PutArchiveImportFile.call(local_path: in_file.path,
                                      remote_path: f)

            DeleteEtlImportFile.call(remote_path: f)
            success += 1

            begin
              processor = category_processor(transaction_file, user)
              processor&.suggest_categories
            rescue StandardError => e
              Rails.logger.warn("Failed suggesting category: #{e.message}")
            end
          else
            raise Exceptions::TransactionFileError,
                  "File generated invalid transaction record [#{f}]"
          end
          @result = true
        rescue Exceptions::TransactionFileError, ArgumentError => e
          # invalid transaction file or some other file handling issue
          # move file to quarantine
          Rails.logger.warn("Quarantining file because: #{e}")
          PutQuarantineFile.call(local_path: in_file.path,
                                 remote_path: f)
          DeleteEtlImportFile.call(remote_path: f)
          quarantined += 1
        rescue StandardError => e
          Rails.logger.warn("Failed to import file: #{e}")
          failed += 1
        ensure
          in_file.close
          in_file.unlink
          out_file.close
          out_file.unlink
        end
      end

      Rails.logger.info(
        "Successfully copied #{success} files, failed to copy #{failed}, quarantined #{quarantined} files"
      )
    ensure
      SystemConfig.config.stop_import
    end
  end

  def category_processor(header, user)
    "Permits::#{header.regime.slug.capitalize}CategoryProcessor".constantize.new(header, user)
  end
end
