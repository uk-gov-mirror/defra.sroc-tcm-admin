# frozen_string_literal: true

# run with: bundle exec rails runner benchmark/pre_sroc_summary.rb
#
require "benchmark/ips"

Benchmark.ips do |x|
  regime = Regime.first
  puts "\n--------------------------------------"
  puts "Regime: #{regime.title}"
  puts "Unbilled transactions: #{regime.transaction_details.unbilled.count}"
  puts "Total regime transactions: #{regime.transaction_details.count}"
  puts "Total system transactions: #{TransactionDetail.count}"
  puts "--------------------------------------\n\n"

  x.report("summary A") do |_times|
    Query::PreSrocSummary.call(regime: regime,
                               region: "A")
  end

  x.report("summary B") do |_times|
    Query::PreSrocSummary.call(regime: regime,
                               region: "B")
  end

  x.compare!
end
