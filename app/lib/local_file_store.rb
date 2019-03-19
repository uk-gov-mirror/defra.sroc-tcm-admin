# frozen_string_literal: true
require "fileutils"

class LocalFileStore
  attr_reader :base_path

  def initialize(base_path = "")
    @base_path = Rails.root.join("tmp", "files", base_path)
    FileUtils.mkdir_p @base_path unless Dir.exist? @base_path
  end

  def list(path = "")
    file_root = Pathname.new(file_path(""))
    Dir.glob(File.join(file_path(path), "**", "*")).select { |f| File.file?(f) }.map {|f| Pathname.new(f).relative_path_from(file_root).to_s }
  end

  # to_path can be file path or io object
  def fetch_file(from_path, to_path)
    src = file_path(from_path)
    if File.exists?(src)
      FileUtils.cp(src, to_path)
    else
      raise Exceptions::FileNotFoundError.new("Local file storage file not found: #{from_path}")
    end
  end

  # stream file from disk
  def store_file(from_path, to_path)
    dst = file_path(to_path)
    x = FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(from_path, dst)
  rescue => e
    raise Exceptions::FileNotFoundError.new("Local file storage file not found: #{from_path}")
  end

  def delete_file(path)
    dst = file_path(path)
    if File.exists?(dst)
      FileUtils.rm(dst)
    else
      raise Exceptions::FileNotFoundError.new("Local file storage file not found: #{path}")
    end
  end
private
  def file_path(path)
    File.join(@base_path, path)
    # Rails.root.join("tmp", "files", path)
  end
end
