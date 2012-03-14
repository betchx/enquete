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

key_id = ans

# read  data body
body = CSV.parse(f)

# 列数
ncol = head.size

# 各列でキーを取得する．
keys = [nil]  # １列目は処理しない．

1.upto(ncol-1) do |ic|
  keys << body.map{|x|  x[i]}.sort.uniq
end

# クロス集計列ごとにデータを分類
# dataは3次元配列になっている
data = []
pkey = keys[key_id]

pkey.each do |key|
  data << body.select{|x| x[key_id] == key}
end







