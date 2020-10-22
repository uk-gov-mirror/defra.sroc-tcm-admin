# frozen_string_literal: true

class FixPre2000FinancialYearDates < ActiveRecord::Migration[5.1]
  def up
    importer = TransactionFileImporter.new
    arel = TransactionDetail.arel_table
    date = Date.parse('1-APR-2001')
    TransactionDetail.where(arel[:period_start].lt(date)).each do |t|
      t.tcm_financial_year = importer.determine_financial_year(t.period_start)
      t.save!
    end
  end

  def down
  end
end
