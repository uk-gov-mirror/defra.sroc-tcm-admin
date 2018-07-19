if Regime.count.zero?
  Regime.create!(name: 'PAS', title: 'Installations')
  Regime.create!(name: 'CFD', title: 'Water Quality')
  Regime.create!(name: 'WML', title: 'Waste')
end

# r = Regime.find_by!(slug: 'pas')
# r.permit_categories.destroy_all
# PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'installations.csv'))
#
# %w[ A B E N S Y ].each do |region|
#   SequenceCounter.find_or_create_by(regime_id: r.id, region: region)
# end
#
# if r.exclusion_reasons.count.zero?
#   [
#     "Extra line auto-created by feeder system",
#     "Extra line created by PAS manual invoice function (permit category)",
#     "Extra line created by PAS manual invoice function (temporary cessation)"
#   ].each do |reason|
#     r.exclusion_reasons.create!(reason: reason, active: true)
#   end
# end

r = Regime.find_by!(slug: 'cfd')
# r.permit_categories.destroy_all
# PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'water_quality.csv'))
#
# %w[ A B E N S T Y ].each do |region|
#   SequenceCounter.find_or_create_by(regime_id: r.id, region: region)
# end
#
# one time task to extract consent references for cfd transactions
tfi = TransactionFileImporter.new
r.transaction_details.each do |t|
  refs = tfi.extract_consent_fields(t.line_description)
  if refs
    t.update_attributes(reference_4: refs[:reference_4])
  end
end

# r = Regime.find_by!(slug: 'wml')
# r.permit_categories.destroy_all
# PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'waste.csv'))
#
# %w[ A B E N S T U Y ].each do |region|
#   SequenceCounter.find_or_create_by(regime_id: r.id, region: region)
# end
#
if User.count.zero?
  u = User.new(first_name: 'Tony',
               last_name: 'Headford',
               email: 'tony@binarycircus.com',
               role: 'admin',
               password: "Ab0#{Devise.friendly_token.first(8)}")
  u.regime_users.build(regime_id: Regime.first.id, enabled: true) 
  u.save!
end

unless User.where(email: 'system@example.com').exists?
  u = User.new(first_name: 'System',
               last_name: 'Account',
               email: 'system@example.com',
               role: 'admin',
               password: "Ab0#{Devise.friendly_token.first(8)}")
  u.regime_users.build(regime_id: Regime.first.id, enabled: true) 
  u.save!
end
