# run with: bundle exec rails runner benchmark/permit_category_lookup.rb
#
require 'benchmark/ips'

Benchmark.ips do |x|
  regime = Regime.first
  puts "\n--------------------------------------"
  puts "Regime: #{regime.title}"
  puts "Permit Category records: #{regime.permit_categories.count}"
  puts "Total system categories: #{PermitCategory.count}"
  puts "--------------------------------------\n\n"

  x.report("base query") do |times|
    Query::PermitCategoryLookup.call(regime: regime,
                                     financial_year: '1819').count
  end

  x.report("with search") do |times|
    Query::PermitCategoryLookup.call(regime: regime,
                                     financial_year: '1819',
                                     query: '1.2').count
  end

  x.compare!
end
