# frozen_string_literal: true

class ChangeSequenceColumnDefault < ActiveRecord::Migration[5.1]
  def change
    change_column_default :sequence_counters, :file_number, 50001
  end
end
