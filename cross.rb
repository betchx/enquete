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

#output
out_file = arg_or_query("出力先（TeX/CSV）","cross_out.csv","output")
tex_out = out_file =~ /\.tex$/i

out = nil
head_line = ["",pkey].flatten
empty_line = head_line.map{ "" }

if tex_out
  out = open(out_file,"w")
  # output header
  out.puts <<-'NNN'
\documentclass[a4paper]{jarticle}
\begin{document}
\tableofcontents
  NNN
else
  out_io = open(out_file,"w")
  out = CSV::Writer.generate(out_io)
end

1.upto(ncol-1) do |ic|
  if tex_out
    out.puts "\\subsection{#{head[ic]}}"
  else
    out << empty_line  #空行
    head_line[0] = head[ic] #ヘッダ行の変更
    out << head_line  #ヘッダ行
  end

=begin
  # get total count to sort
  totals = keys[ic].map do |key|
    num = 0
    body.each do |row|
      num += 1 if row[ic] == key
    end
    [num,key]
  end
=end

  sorted_pair = totals.sort_by{|a,b| a}
  skey = sorted_pair.map{|a,b| b}

  res = keys[ic].map do |key|
    data.map do |chunk|
      chunk.select{|x| x[ic] == key}.size
    end
  end
  # calculate total
  res.each do |chunk|
    chunk << chunk.inkect{|r,x| x + r}
  end

  # sort
  result =  res.sort_by{|x| x[-1]}

  
end

if tex_out
  # output footer
  out.puts <<-'NNN'
\end{document}
  NNN
  out.close
else
  out_io.close
end


