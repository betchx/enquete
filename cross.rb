#! ruby
# coding: utf-8


require 'csv'
require 'arg_or_query'
require 'nkf'

source = arg_or_query("enquate csv file", "enquate.csv","soure file")

#f = open(source)
#head = CSV.parse_line(f.gets)

f = CSV.open(source,'r')
question = f.shift

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
    puts "#{i}: #{NKF.nkf('-w',head[i])}"
  end
  puts "入力？（空行で次の行を表示)>"
  ans = gets.to_i
end
else
  ans = ARGV.shift.to_i
end

key_id = ans


# 列数
ncol = question.size

# read  data body
body = []
f.each do |row|
  body << row
end

def check(value, key)
  return false if value.nil? || value.empty?
  value.split(/,/).each do |x|
    return true if x.strip == key
  end
  return false
end

# 各列でキーを取得する．
all_key = [nil]  # １列目は処理しない．

1.upto(ncol-1) do |ic|
  all_key << body.map{|x| x[ic]}.compact.map{|x|
    x.split(/,/).map{|s| s.strip}
  }.flatten.sort.uniq.reject{|x| x =~ /^----/}
end

# クロス集計列ごとにデータを分類
# dataは3次元配列になっている
data = []
pkey = all_key[key_id]

pkey.each do |key|
  data << body.select{|x| check(x[key_id], key)}
end

#output
out_file = arg_or_query("出力先（TeX/CSV）","cross_out.csv","output")
tex_out = out_file =~ /\.tex$/i

out = nil
head_line = ["",pkey,"Total\n"].flatten
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

=begin
# debug
dbout = CSV.open("keys.csv","w")
all_key.each_with_index do |key,i|
  dbout << [i,key].flatten
end
dbout.close
=end

FREE_TAG = [ /自由に書いて/,/その理由は/,
/具体的に記述/,/上記以外にどんなものがあればよかったですか/,
]

1.upto(ncol-1) do |ic|
  keys = all_key[ic].clone
  toi = NKF.nkf("-w",question[ic])
  
  is_free = false
  FREE_TAG.each do |re|
    is_free = true if toi =~ re
  end

  if is_free
    if tex_out
      out.puts "\\subsection{#{head[ic]}}"
      out.puts '\begin{itemize}'
    else
      out << empty_line  #空行
      out << [NKF.nkf("-s","自由意見："),question[ic]]
      out << [question[key_id], NKF.nkf("-s","回答\n")]
    end

    # loop
    pkey.size.times do |ikey|
      res = [pkey[ikey],""]
      data[ikey].map{|x| x[ic]}.compact.each do |iken|
        res[1] =  iken
        if tex_out
          out.puts "\\item #{iken}(#{res[0]})"
          #out.print res.join(' & ')
          #out.puts '\\ \hline'
        else
          out << res
        end
      end
    end
    if tex_out
      out.puts "\\end{itemize}"
      #out.puts "\\end{tabular}"
    end
    next  # Go to Next question
  end

  if tex_out
    out.puts "\\subsection{#{head[ic]}}"
    out.puts '\begin{tabular}{c'+'r'*pkey.size+'}'
    out.puts head_line.join(' & ')+'\\'
  else
    out << empty_line  #空行
    head_line[0] = question[ic] #ヘッダ行の変更
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
  sorted_pair = totals.sort_by{|a,b| a}
  skey = sorted_pair.map{|a,b| b}
=end

  res = keys.map do |key|
    arr = data.map do |chunk|
      chunk.select{|x| check(x[ic], key)}.size
    end
    arr.unshift key
    arr
  end

  # calculate total
  res.each do |arr|
    arr << arr[1..-1].inject{|r,x| x + r}
  end

  # sort
  result =  res.sort_by{|x| -x[-1]}

  #output
  if tex_out
    result.each do |r|
      out.puts r.join(' & ')
      out.puts '\\\hline'
    end
    out.puts '\end{tabular}'
  else
    result.each do |r|
      out << r
    end
  end

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


