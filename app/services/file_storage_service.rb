# frozen_string_literal: true

class FileStorageService
  attr_reader :user
  # STORAGE_ZONES = [:import, :export, :archive, :quarantine].freeze
  STORAGE_ZONES = {
    import: "import",
    export: "export",
    annual_billing_data: "annual_billing_data",
    import_archive: "archive/import",
    export_archive: "archive/export",
    csv_export: "csv",
    quarantine: "quarantine"
  }

  def initialize(user = nil)
    # when instantiated from a controller the 'current_user' should
    # be passed in. This will allow us to audit actions etc. down the line.
    @user = user
  end

  def list_files_in(zone)
    path = zone_path(zone)
    files = storage.list path
    files.select { |f| f != path }.map { |f| f.sub(path, "") }
  end

  def fetch_file_from(zone, from_path, to_path)
    storage.fetch_file(zone_path(zone, from_path), to_path)
  end

  def store_file_in(zone, from_path, to_path)
    storage.store_file(from_path, zone_path(zone, to_path))
  end

  def delete_file_from(zone, file_path)
    storage.delete_file(zone_path(zone, file_path))
  end

private
  def storage
    @storage ||= determine_storage_handler
  end

  def zone_path(z, path = "")
    raise ArgumentError.new("Unknown zone: #{z}") unless STORAGE_ZONES.include?(z)
    File.join(STORAGE_ZONES[z], path)
  end

  def determine_storage_handler
    if Rails.env.development? || Rails.env.test?
      LocalFileStore.new
    else
      AwsFileStore.new
    end
  end
end
