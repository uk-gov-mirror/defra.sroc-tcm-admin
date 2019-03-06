# frozen_string_literal: true

module FileStorage
  def etl_file_store
    if Rails.env.development? || Rails.env.test?
      LocalFileStore.new("etl_bucket")
    else
      EtlFileStore.new
    end
  end

  def archive_file_store
    if Rails.env.development? || Rails.env.test?
      LocalFileStore.new("archive_bucket")
    else
      ArchiveFileStore.new
    end
  end
end
