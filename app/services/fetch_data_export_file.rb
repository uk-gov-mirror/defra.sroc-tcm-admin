require 'digest'
require 'fileutils'

class FetchDataExportFile < ServiceObject

  attr_reader :regime, :filename

  def initialize(params = {})
    @regime = params.fetch(:regime)
    @edf = @regime.export_data_file
    @filename = nil
  end

  def call
    # retrieve file from cache or S3
    @filename = cache_or_retrieve @edf.exported_filename      
    @result = filename.present?
    self
  end

  private

  def cache_or_retrieve(file)
    cached_filename = cached_file_path(file)

    return cached_filename if cached_file_matches_stored_hash?(cached_filename)

    # pull file from S3
    storage.fetch_file_from(:csv_export, file, cached_filename)

    # verify checksum
    raise RuntimeError.new("Checksum does not match stored file") unless check_file_hash(cached_filename)

    cached_filename
  end

  def cached_file_path(file)
    Rails.root.join(cache_path, file)
  end

  def cached_file_matches_stored_hash?(file)
    File.exist?(file) && check_file_hash(file)
  end

  def check_file_hash(file)
    @edf.exported_filename_hash == generate_file_hash(file)
  end

  def generate_file_hash(file)
    Digest::SHA1.file(file).hexdigest
  end

  def cache_path
    path = Rails.root.join('tmp', 'cache', 'export_data')
    FileUtils.mkdir_p path unless Dir.exist? path
    path
  end

  def storage
    @storage ||= FileStorageService.new
  end
end
