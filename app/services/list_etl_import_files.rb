# frozen_string_literal: true

class ListEtlImportFiles < ServiceObject
  include FileStorage

  attr_reader :files

  def initialize(params = {})
    @files = []
  end

  def call
    @files = etl_file_store.list('import').reject do |f|
      # reject any "directories"
      f.end_with?(File::Separator)
    end

    @result = true
    self
  end
end
