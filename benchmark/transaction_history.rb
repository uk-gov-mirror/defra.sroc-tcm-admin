# frozen_string_literal: true

# run with: bundle exec rails runner benchmark/transaction_history.rb
#
require "benchmark/ips"

Benchmark.ips do |x|
  regime = Regime.first
  puts "\n--------------------------------------"
  puts "Regime: #{regime.title}"
  puts "Billed transactions: #{regime.transaction_details.historic.count}"
  puts "Total regime transactions: #{regime.transaction_details.count}"
  puts "Total system transactions: #{TransactionDetail.count}"
  puts "--------------------------------------\n\n"

  x.report("base query") do |_times|
    Query::BilledTransactions.call(regime: regime).count
  end

  x.report("with region") do |_times|
    Query::BilledTransactions.call(regime: regime,
                                   region: "A").count
  end

  x.report("with financial year") do |_times|
    Query::BilledTransactions.call(regime: regime,
                                   financial_year: "1819").count
  end

  x.report("with search") do |_times|
    Query::BilledTransactions.call(regime: regime,
                                   search: "2HQ").count
  end

  x.report("sorted asc") do |_times|
    Query::BilledTransactions.call(regime: regime,
                                   sort: :reference_1,
                                   sort_direction: "asc").count
  end

  x.report("sorted desc") do |_times|
    Query::BilledTransactions.call(regime: regime,
                                   sort: :reference_2,
                                   sort_direction: "desc").count
  end

  x.report("multiple options") do |_times|
    Query::BilledTransactions.call(regime: regime,
                                   region: "A",
                                   financial_year: "1819",
                                   sort: :reference_1,
                                   sort_direction: "desc",
                                   search: "2HQ").count
  end

  x.compare!
end
