class IndexTransactions < ActiveRecord::Migration[5.1]
  def change
    add_index :transaction_details, [:transaction_header_id, :status],
      name: 'th_td_status' #, order: { customer_reference: :asc }

    # superfluous
    # add_index :transaction_details, [:transaction_header_id, :status, :region],
    #   name: 'th_td_status_region'

    add_index :transaction_details,
      [:transaction_header_id, :status, :tcm_financial_year],
      name: 'th_td_status_fy'

    add_index :transaction_details,
      [:transaction_header_id, :status, :region, :tcm_financial_year],
      name: 'th_td_status_region_fy'

    add_index :regimes, :slug, unique: true, name: 'th_regime_slug'
  end
end
