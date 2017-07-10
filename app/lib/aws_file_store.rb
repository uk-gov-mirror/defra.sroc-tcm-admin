# frozen_string_literal: true

class AwsFileStore
  attr_reader :base_path

  def initialize(path)
    @base_path = File.join(path.to_s, "/")
  end

  def list(path = "")
    resp = s3.list_objects_v2(bucket: s3_bucket_name, prefix: rebase_path(path))
    resp.contents.select { |f| f.key != base_path }.map { |f| f.key.sub(base_path, "") }
  rescue Aws::S3::Errors::AccessDenied => e
    raise Exceptions::PermissionError.new("No permission to list: #{path}")
  end

  # to_path can be file path or io object
  def fetch_file(from_path, to_path)
    s3.get_object(bucket: s3_bucket_name, key: rebase_path(from_path), response_target: to_path)
  rescue Aws::S3::Errors::NoSuchKey => e
    raise Exceptions::FileNotFoundError.new("AWS S3 storage file not found: #{from_path}")
  rescue Aws::S3::Errors::AccessDenied => e
    raise Exceptions::PermissionError.new("No permission to access file: #{from_path}")
  end

  # stream file from disk
  def store_file(from_path, to_path)
    File.open(from_path, "rb") do |file|
      s3.put_object(bucket: s3_bucket_name, key: rebase_path(to_path), body: file)
    end
  rescue Errno::ENOENT => e
    raise Exceptions::FileNotFoundError.new("Cannot open file: #{from_path}")
  rescue Aws::S3::Errors::NoSuchKey => e
    raise Exceptions::FileNotFoundError.new("AWS S3 storage file not found: #{to_path}")
  rescue Aws::S3::Errors::AccessDenied => e
    raise Exceptions::PermissionError.new("No permission to access file: #{to_path}")
  end

  def delete_file(file_path)
    # NOTE: this doesn't raise a S3 error if the key is not found
    s3.delete_object(bucket: s3_bucket_name, key: rebase_path(file_path))
  rescue Aws::S3::Errors::AccessDenied => e
    raise Exceptions::PermissionError.new("No permission to access file: #{file_path}")
  end

#private
  def rebase_path(path)
    File.join(base_path, path)
  end

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
