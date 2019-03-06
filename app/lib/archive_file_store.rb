# frozen_string_literal: true

class ArchiveFileStore < AwsFileStore
  def s3_bucket_name
    ENV["ARCHIVE_BUCKET"]
  end
end
