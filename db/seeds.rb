if Regime.count.zero?
  Regime.create!(name: 'PAS', title: 'Installations')
  Regime.create!(name: 'CFD', title: 'Water Quality')
  Regime.create!(name: 'WML', title: 'Waste')
end

Regime.all.each do |r|
  ExportDataFile.find_or_create_by!(regime_id: r.id) do |edf|
    edf.status = 'pending'
    edf.compress = true
  end
end

if User.count.zero?
  u = User.new(first_name: 'System',
               last_name: 'Account',
               email: 'system@example.com',
               role: 'admin',
               password: "Ab0#{Devise.friendly_token.first(8)}")
  u.regime_users.build(regime_id: Regime.first.id, enabled: true)
  u.save!
end

unless User.where(email: 'stu@silverka.co.uk').exists?
  u = User.new(first_name: 'Stuart',
               last_name: 'Adair',
               email: 'stu@silverka.co.uk',
               role: 'admin',
               password: "Ab0#{Devise.friendly_token.first(8)}")
  u.regime_users.build(regime_id: Regime.first.id, enabled: true)
  u.save!
end

r = Regime.find_by!(slug: 'pas')
r.permit_categories.destroy_all
PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'installations.csv'))

%w[ A B E N S Y ].each do |region|
  SequenceCounter.find_or_create_by(regime_id: r.id, region: region)
end

r = Regime.find_by!(slug: 'cfd')
r.permit_categories.destroy_all
PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'water_quality.csv'))

%w[ A B E N S T Y ].each do |region|
  SequenceCounter.find_or_create_by(regime_id: r.id, region: region)
end

r = Regime.find_by!(slug: 'wml')
r.permit_categories.destroy_all
PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'waste.csv'))

%w[ A B E N S T U Y ].each do |region|
  SequenceCounter.find_or_create_by(regime_id: r.id, region: region)
end

# add region to all transactions
TransactionHeader.all.each do |h|
  h.transaction_details.update_all(region: h.region)
end

# fix up transaction files
TransactionFile.where(file_reference: nil).each do |f|
  f.credit_count = f.transaction_details.credits.count
  f.debit_count = f.transaction_details.invoices.count
  f.net_total = f.invoice_total + f.credit_total
  f.file_reference = f.base_filename
  f.save!
end

# fix up TransactionHeader file references
TransactionHeader.where(file_reference: nil).each do |th|
  th.send :generate_file_reference
  th.save!
end
