require 'csv'

if ARGV.size < 1
  puts "Usage: rateamento-aws aws-cost-allocation-file.csv [tag-name]"
end

tag_name = ARGV[1] || 'user:produto'

costs_by_product = Hash.new(0)
others_costs = Hash.new(0)
total_others_costs = 0.0
total_cost = 0.0

CSV.foreach(ARGV[0], col_sep: ',', encoding: 'utf-8', headers: true, skip_lines: /\ADon't see your tags/) do |row|
  if row['RecordType'] == 'PayerLineItem'
    row_total_cost = row['TotalCost'].to_f
    if row_total_cost > 0
      if row[tag_name]
        costs_by_product[row[tag_name]] += row_total_cost
      else
        others_costs[row['UsageType']] += row_total_cost
        total_others_costs += row_total_cost
      end
      total_cost += row_total_cost
    end
  end
end

costs_by_product.each do |key, value|
  puts "#{key}: #{value.round(2)}"
end
puts "Others costs: #{total_others_costs.round(2)}"
puts "Total: #{total_cost.round(2)}"

puts
puts 'Others cost detail:'
others_costs.each do |key, value|
  puts "#{key}: #{value.round(2)}"
end
