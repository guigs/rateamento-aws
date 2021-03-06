require 'csv'

if ARGV.size < 1
  puts "Usage: rateamento-aws aws-cost-allocation-file.csv [total-in-local-currency] [tag-name]"
  exit
end

total_local = ARGV[1].to_f if ARGV[1]
tag_name = ARGV[2] || 'user:produto'

costs_by_product = Hash.new(0)
others_costs = Hash.new(0)
total_others_costs = 0.0
total_cost = 0.0

CSV.foreach(ARGV[0], col_sep: ',', encoding: 'utf-8', headers: true, skip_lines: /Don't see your tags/) do |row|
  if row['RecordType'] == 'PayerLineItem'
    row_total_cost = row['TotalCost'].to_f
    if row_total_cost > 0
      if row[tag_name] && !row[tag_name].empty?
        costs_by_product[row[tag_name]] += row_total_cost
      elsif row['UsageType'] =~ /HeavyUsage/
        costs_by_product[row['UsageType']] += row_total_cost
      else
        others_costs[row['UsageType']] += row_total_cost
        total_others_costs += row_total_cost
      end
      total_cost += row_total_cost
    end
  end
end

total_local = total_cost unless total_local

format_value = -> (value) do
  "US$ #{'%7.2f' % value.round(2)}   R$ #{('%7.2f' % (total_local * value/total_cost).round(2)).gsub('.', ',')}"
end

puts "Exchange rate: R$ #{(total_local/total_cost).round(3)}"

costs_by_product.each do |key, value|
  puts "#{'%30s' % key}: #{format_value.(value)}"
end
puts "#{'%30s' % 'Others costs'}: #{format_value.(total_others_costs)}"
puts "#{'%30s' % 'Total'}: #{format_value.(total_cost)}"

puts
puts 'Others cost detail:'
others_costs.each do |key, value|
  puts "#{'%30s' % key}: #{format_value.(value)}"
end
