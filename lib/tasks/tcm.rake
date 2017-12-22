namespace :tcm do
  desc 'Delete all transaction records from the database'
  task :cleardown => :environment do
    TransactionHeader.destroy_all
  end
end
