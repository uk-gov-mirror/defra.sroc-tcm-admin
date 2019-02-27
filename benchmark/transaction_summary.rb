# run with: bundle exec rails runner benchmark/transaction_summary.rb
#
require 'benchmark/ips'

Benchmark.ips do |x|
  regime = Regime.first
  puts "\n--------------------------------------"
  puts "Regime: #{regime.title}"
  puts "Unbilled transactions: #{regime.transaction_details.unbilled.count}"
  puts "Total regime transactions: #{regime.transaction_details.count}"
  puts "Total system transactions: #{TransactionDetail.count}"
  puts "--------------------------------------\n\n"

  x.report("summary A") do |times|
    Query::TransactionSummary.call(regime: regime,
                                   region: 'A')
  end

  x.report("summary B") do |times|
    Query::TransactionSummary.call(regime: regime,
                                   region: 'B')
  end

  x.compare!
end
