# run with: bundle exec rails runner benchmark/transactions_to_be_billed.rb
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

  x.report("base query") do |times|
    Query::TransactionsToBeBilled.call(regime: regime).count
  end

  x.report("with region") do |times|
    Query::TransactionsToBeBilled.call(regime: regime,
                                       region: 'A').count
  end

  x.report("with financial year") do |times|
    Query::TransactionsToBeBilled.call(regime: regime,
                                       financial_year: '1819').count
  end

  x.report("with search") do |times|
    Query::TransactionsToBeBilled.call(regime: regime,
                                       search: '8RH').count
  end

  x.report("sorted asc") do |times|
    Query::TransactionsToBeBilled.call(regime: regime,
                                       sort: :reference_1,
                                       sort_direction: 'asc').count
  end

  x.report("sorted desc") do |times|
    Query::TransactionsToBeBilled.call(regime: regime,
                                       sort: :reference_2,
                                       sort_direction: 'desc').count
  end

  x.report("multiple options") do |times|
    Query::TransactionsToBeBilled.call(regime: regime,
                                       region: 'A',
                                       financial_year: '1819',
                                       sort: :reference_1,
                                       sort_direction: 'desc',
                                       search: 'VN').count
  end

  x.compare!
end
