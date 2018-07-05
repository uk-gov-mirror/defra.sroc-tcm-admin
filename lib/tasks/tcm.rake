namespace :tcm do
  desc 'Delete all transaction records from the database'
  task :cleardown => :environment do
    TransactionHeader.destroy_all
  end

  desc 'Check process running'
  task :check_rails_running => :environment do
    path = Rails.root.join('tmp', 'pids', 'server.pid')
    rails_running = true
    if File.exists? path
      pid = File.read(path).to_i
      begin
        Process.getpgid pid
      rescue Errno::ESRCH
        rails_running = false
      end
    else
      rails_running = false
      pid = '???'
    end

    if rails_running
      puts "Rails running (pid: #{pid})"
    else
      abort("Cannot find rails process (pid: #{pid})")
    end
  end

  desc 'Check charging service accessible'
  task :check_charge_service => :environment do
    result = CalculationService.new.check_connectivity
    abort('Cannot generate charge') unless result &&
      result["calculation"] &&
      result["calculation"]["chargeValue"]
  end
end
