# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Regime.count.zero?
  Regime.create!(name: 'PAS', title: 'Installations')
  Regime.create!(name: 'CFD', title: 'Water Quality')
  Regime.create!(name: 'WaBS', title: 'Waste')
end

r = Regime.find_by!(slug: 'pas')
PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'installations.csv'))

r = Regime.find_by!(slug: 'cfd')
PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'water_quality.csv'))

r = Regime.find_by!(slug: 'wabs')
PermitCategoryImporter.import(r, Rails.root.join('db', 'categories', 'waste.csv'))
