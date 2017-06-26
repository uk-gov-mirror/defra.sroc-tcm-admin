# frozen_string_literal: true

class FileStorageService
  attr_reader :user
  STORAGE_ZONES = [:import, :export, :archive].freeze

  def initialize(user = nil)
    # when instantiated from a controller the 'current_user' should
    # be passed in. This will allow us to audit actions etc. down the line.
    @user = user
    @storage_zones = {}
  end

  def list_files_in(zone)
    storage(zone).list
  end

  def fetch_file_from(zone, from_path, to_path)
    storage(zone).fetch_file(from_path, to_path)
  end

  def store_file_in(zone, from_path, to_path)
    storage(zone).store_file(from_path, to_path)
  end

  def delete_file_from(zone, file_path)
    storage(zone).delete_file(file_path)
  end

private
  def storage(zone)
    @storage_zones[zone.to_sym] ||= determine_storage_handler_for(zone)
  end

  def determine_storage_handler_for(zone)
    z = zone.to_sym
    raise ArgumentError.new("Unknown zone: #{zone}") unless STORAGE_ZONES.include?(z)
    if ENV.fetch("USE_LOCAL_FILE_STORAGE", false)
      LocalFileStore.new(z)
    else
      AwsFileStore.new(z)
    end
  end
end
