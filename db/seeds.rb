# frozen_string_literal: true

def create_user(details)
  user = User.new(
    first_name: details["firstname"],
    last_name: details["lastname"],
    email: details["email"],
    role: details["role"],
    password: ENV["DEFAULT_PASSWORD"]
  )

  add_regimes_to_user(user, details["regimes"])

  user.save!
end

def add_regimes_to_user(user, regimes)
  regimes.each do |name|
    regime = Regime.find_by(name: name)
    user.regime_users.build(regime_id: regime.id, enabled: true)
  end
end

def seed_users
  seeds = JSON.parse(File.read("#{Rails.root}/db/seeds/users.json"))
  users = seeds["users"]

  users.each do |user|
    create_user(user) unless User.where(email: user["email"]).exists?
  end
end

if Regime.count.zero?
  Regime.create!(name: "PAS", title: "Installations")
  Regime.create!(name: "CFD", title: "Water Quality")
  Regime.create!(name: "WML", title: "Waste")
end

Regime.all.each do |r|
  ExportDataFile.find_or_create_by!(regime_id: r.id) do |edf|
    edf.status = "pending"
    edf.compress = true
  end
end

seed_users

r = Regime.find_by!(slug: "pas")
r.permit_categories.destroy_all
PermitCategoryImporter.import(r, Rails.root.join("db", "categories", "installations.csv"))

%w[A B E N S Y].each do |region|
  SequenceCounter.find_or_create_by(regime_id: r.id, region: region)
end

r = Regime.find_by!(slug: "cfd")
r.permit_categories.destroy_all
PermitCategoryImporter.import(r, Rails.root.join("db", "categories", "water_quality.csv"))

%w[A B E N S T Y].each do |region|
  SequenceCounter.find_or_create_by(regime_id: r.id, region: region)
end

r = Regime.find_by!(slug: "wml")
r.permit_categories.destroy_all
PermitCategoryImporter.import(r, Rails.root.join("db", "categories", "waste.csv"))

%w[A B E N S T U Y].each do |region|
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
