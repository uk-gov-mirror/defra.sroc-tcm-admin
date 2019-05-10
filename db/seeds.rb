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

  # # update fix for permit category
  # q = r.transaction_details.historic
  # missing = q.group(:category, :category_description, :tcm_financial_year).
  #   having(category_description: nil).count
  #
  # missing.keys.each do |k|
  #   code = k[0]
  #   fy = k[2]
  #   if code
  #     pc = r.permit_categories.by_financial_year(fy).active.
  #       where(code: code).first
  #     if pc
  #       q.where(category: code, tcm_financial_year: fy,
  #               category_description: nil).
  #               update_all(category_description: pc.description)
  #     end
  #   end
  # end
end

# Too memory intensive - ran out of memory in preprod with ~ 50,000 records to update
# Regime.all.each do |r|
#   r.transaction_details.historic.where(category_description: nil).each do |t|
#     fy = t.tcm_financial_year
#     code = t.category
#
#     if code
#       pc = r.permit_categories.by_financial_year(fy).active.
#         where(code: code).first
#       t.update_attributes(category_description: pc.description) unless pc.nil?
#     end
#   end
# end

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

# r = Regime.find_by!(slug: 'cfd')
# r.permit_categories.destroy_all
# PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'water_quality.csv'))
#
# %w[ A B E N S T Y ].each do |region|
#   SequenceCounter.find_or_create_by(regime_id: r.id, region: region)
# end
#
# one time task to extract consent references for cfd transactions
# tfi = TransactionFileImporter.new
# r.transaction_details.each do |t|
#   refs = tfi.extract_consent_fields(t.line_description)
#   if refs
#     t.update_attributes(reference_4: refs[:reference_4])
#   end
# end

# r = Regime.find_by!(slug: 'wml')
# tfi = TransactionFileImporter.new
# retro extract the charge code and store in reference_3
# this is needed for future years biling
# r.transaction_details.each do |td|
#   cc = tfi.extract_charge_code(td.line_description)
#   td.update_attributes(reference_3: cc) unless cc.nil?
# end

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

# add region to all transactions
TransactionHeader.all.each do |h|
  h.transaction_details.update_all(region: h.region)
end

# fix up transaction files
# Thread.current[:current_user] = User.system_account
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
