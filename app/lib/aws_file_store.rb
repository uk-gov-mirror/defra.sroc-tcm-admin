# frozen_string_literal: true

class AwsFileStore
  def list(path = "")
    options = { bucket: s3_bucket_name }
    options[:prefix] = path if path.present?
    resp = s3.list_objects_v2(options)
    files = resp.contents.map(&:key)

    # handle 1000 file batching limit
    while resp.is_truncated
      options[:continuation_token] = resp.next_continuation_token
      resp = s3.list_objects_v2(options)
      files += resp.contents.map(&:key)
    end

    files
  rescue Aws::S3::Errors::AccessDenied
    raise Exceptions::PermissionError, "No permission to list: #{path}"
  end

  # to_path can be file path or io object
  def fetch_file(from_path, to_path)
    s3.get_object(bucket: s3_bucket_name, key: from_path, response_target: to_path)
  rescue Aws::S3::Errors::NoSuchKey
    raise Exceptions::FileNotFoundError, "AWS S3 storage file not found: #{from_path}"
  rescue Aws::S3::Errors::AccessDenied
    raise Exceptions::PermissionError, "No permission to access file: #{from_path}"
  end

  # stream file from disk
  def store_file(from_path, to_path)
    File.open(from_path, "rb") do |file|
      s3.put_object(bucket: s3_bucket_name, key: to_path, body: file)
    end
  rescue Errno::ENOENT
    raise Exceptions::FileNotFoundError, "Cannot open file: #{from_path}"
  rescue Aws::S3::Errors::NoSuchKey
    raise Exceptions::FileNotFoundError, "AWS S3 storage file not found: #{to_path}"
  rescue Aws::S3::Errors::AccessDenied
    raise Exceptions::PermissionError, "No permission to access file: #{to_path}"
  end

  def delete_file(file_path)
    # NOTE: this doesn't raise a S3 error if the key is not found
    s3.delete_object(bucket: s3_bucket_name, key: file_path)
  rescue Aws::S3::Errors::AccessDenied
    raise Exceptions::PermissionError, "No permission to access file: #{file_path}"
  end

  # extras that can be useful

  # copy object within s3 (this implementation is within our bucket but this can work across buckets)
  def copy_file(from_path, to_path)
    s3.copy_object(bucket: s3_bucket_name, copy_source: File.join(s3_bucket_name, from_path), key: to_path)
  rescue Aws::S3::Errors::AccessDenied
    raise Exceptions::PermissionError, "Unable to copy file: #{from_path} to #{to_path}"
  end

  private

  def s3
    @s3 ||= Aws::S3::Client.new(region: aws_region, credentials: credentials)
  end

  def credentials
    Aws::Credentials.new(aws_access_key, aws_secret_key)
  end

  def aws_region
    "eu-west-1"
  end

  def aws_access_key
    ENV["FILE_UPLOAD_ACCESS_KEY"]
  end

  def aws_secret_key
    ENV["FILE_UPLOAD_SECRET_KEY"]
  end

  def s3_bucket_name
    ENV["FILE_UPLOAD_BUCKET"]
  end
end
