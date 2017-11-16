if Regime.count.zero?
  Regime.create!(name: 'PAS', title: 'Installations')
  Regime.create!(name: 'CFD', title: 'Water Quality')
  Regime.create!(name: 'WML', title: 'Waste')
end

r = Regime.find_by!(slug: 'pas')
PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'installations.csv'))

r = Regime.find_by!(slug: 'cfd')
PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'water_quality.csv'))

r = Regime.find_by!(slug: 'wml')
PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'waste.csv'))
