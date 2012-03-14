#! ruby
# coding: utf-8


require 'csv'
require 'arg_or_query'

source = arg_or_query("enquate csv file", "enquate.csv","soure file")

f = open(source)

head = CSV.parse_line(f.gets)

ans = 0
if ARGV.empty?
puts "クロス集計に用いる列を指定してください"
i = 0
while ans == 0
  10.times do
    i = i + 1
    if head[i].nil?
      i = 0
      break
    end
    puts "#{i}: #{head[i]}"
  end
  puts "入力？（空行で次の行を表示)>"
  ans = gets.to_i
end
else
  ans = ARGV.shift.to_i
end

# read  data body
body = CSV.parse(f)





