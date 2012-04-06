#! ruby
# coding: utf-8

require 'csv'
require 'arg_or_query'
require 'nkf'
require 'rubygems'
require 'gruff'
require 'side_stacked_bar_fixed'

def apply_theme(g)
  raise unless $theme
  g.theme = $theme
  g.font = $theme[:font]
  # マージンは最小限に
  g.bottom_margin = 10
  g.top_margin = 0
  g.left_margin = 0
  g.right_margin = 10
  g.title_font_size = $theme[:title_font_size] || 20
  g.legend_font_size = $theme[:legend_font_size]||10
  g.legend_box_size = $theme[:legend_box_size] || g.legend_font_size
  g.legend_margin = $theme[:legend_margin] || g.legend_font_size/4
  g.marker_font_size = $theme[:marker_font_size]||10
  g
end

def utf8(str)
  str.utf8
end
def sjis(str)
  str.sjis
end
class String
  def utf8
    NKF.nkf("-w",self)
  end
  def sjis
    NKF.nkf("-s",self)
  end
end

# 設定を記述したファイルを指定する．
raise "設定ファイルを指定してください．" if ARGV.empty?
template_file = ARGV.shift
require template_file

source = nil
if $source
  source = $source
else
  source = arg_or_query("enquate csv file", "enquate.csv","soure file")
end

f = CSV.open(source,'r')
question = f.shift
head = question.clone

ans = 0
if $column.nil?
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
        puts "#{i}: #{utf8(head[i])}"
      end
      puts "入力？（空行で次の行を表示)>"
      ans = gets.to_i
    end
  else
    ans = ARGV.shift.to_i
  end
else
  ans = $column
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
out_file = $output
out_file = arg_or_query("出力先（TeX/CSV）","cross_out.csv","output") if out_file.nil?
tex_out = out_file =~ /\.tex$/i
# workdir for graphic
$graph_dir = nil
if tex_out
  $graph_dir = out_file.sub(/\.tex$/i,'')
  Dir.mkdir($graph_dir) unless File.directory?($graph_dir)
end

#出力先グラフファイル名を指定する
def gout(ic)
  sprintf("%s/QA-%03d.png",$graph_dir,ic)
end

sec = nil
if $sections
  sec = $sections
else
  sec = {}
  until ARGV.empty?
    key = ARGV.shift
    raise "セクションの設定がまちがっています" unless value = ARGV.shift
    sec[key] = value
  end
end
sec_num = sec.keys.sort

out = nil
# 最後の改行はEXCELで開いたときにヘッダをわかりやすくするため
head_line = ["",pkey,"合計".sjis,"\n"].flatten
empty_line = head_line.map{ "" }

if tex_out
  title = $title || "アンケート集計結果"
  author = $author || "土木学会中部支部"

  out = open(out_file,"w")
  # output header
  txt = <<-"NNN"
\\documentclass[a3paper,landscape]{jsarticle}
\\usepackage[left=1.5cm,top=1cm,bottom=2cm,right=1cm]{geometry}
\\usepackage{longtable}
\\usepackage[dvipdfm]{graphicx}
\\usepackage{multicol}
\\title{#{title}}
\\date{\\today}
\\author{#{author}}
\\begin{document}
\\maketitle
\\vfil

\\begin{multicols}{2}
\\tableofcontents
\\end{multicols}
\\clearpage
  NNN
  out.puts txt.sjis
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

width = 300/(pkey.size+2)

item_width = width * 1.5 + 10

g = nil
labels = nil
gdata = nil
hash_label = {}
if tex_out
  if $theme
    pkey.each_with_index do |v,i|
      hash_label[i] = v.utf8
    end
  end
  out.puts <<-KKK
\\section{#{question[key_id]}#{"内訳".sjis}}
\\begin{tabular}{c#{'r'*pkey.size}r} \\hline
\\multicolumn{1}{p{#{item_width}mm}}{} & 
  KKK
  out.puts pkey.map{|val|
    "\\multicolumn{1}{p{#{width}mm}}{#{val}}"
  }.join(' & ')
  txt = '& \multicolumn{1}{p{1cm}}{合計}\\\\ \hline'
  txt += "\n"
  txt += "回答数&"
  nums = data.map{|x| x.size}
  txt += nums.join('&')
  txt += "& #{nums.inject{|a,b| a+b}}\n"
    txt += "\\\\ \\hline\n\\end{tabular}\n"
  out.puts NKF.nkf('-Ws',txt)
  if $theme
    g = apply_theme(Gruff::SideStackedBarFixed.new('2400x1200')) # changed from Pie
    g.title = "#{question[key_id].utf8}#{"内訳"}"
    g.labels = hash_label
    g.data("回答数",nums,'blue')
    g.hide_legend = true
    g.x_axis_label = "有効回答数"
    g.write(gout(0)) unless $no_png_out
    out.puts <<-NNN
\\vfil
\\begin{center}
\\includegraphics[width=#{$theme[:width]}]{#{gout(0)}}
\\end{center}
    NNN
  end
  out.puts "\\clearpage"
end


1.upto(ncol-1) do |ic|
  next if ic == key_id  # skip same one
  $stderr.puts sprintf("処理中：Q%03d :%s",ic, question[ic].utf8)
  keys = all_key[ic].clone
  toi = utf8(question[ic])

  is_free = false
  FREE_TAG.each do |re|
    is_free = true if toi =~ re
  end
  if tex_out
    if sec_num.include?(ic)
      out.puts "\\clearpage" if $no_table
      out.puts "\\section{#{sec[ic].sjis}}"
    end
  end

  if is_free
    if tex_out
      # output
      out.puts "\\subsection{#{question[ic].sjis}}"
      if $no_table  # omit output
        out.puts "自由意見のため，グラフはありません".sjis
        next
      end
      out.puts '\begin{multicols}{3}'
    else
      out << empty_line  #空行
      out << ["自由意見：".sjis,question[ic]]
      out << [question[key_id], "回答\n".sjis]
    end

    # loop
    pkey.size.times do |ikey|
      res = [pkey[ikey],""]
      target = data[ikey].map{|x| x[ic]}.compact
      next if target.empty?
      if tex_out
        out.puts "\\paragraph{#{res[0]}}"
        out.puts '\begin{itemize}'
      end
      target.each do |iken|
        res[1] =  iken
        if tex_out
          out.puts "\\item #{iken}"
        else
          out << res
        end
      end
      if tex_out
        out.puts "\\end{itemize}"
      end
    end
    if tex_out
      out.puts '\end{multicols}'
      out.puts '\\clearpage'
      #out.puts "\\end{tabular}"
    end
    next  # Go to Next question
  end

  if tex_out
    # graph
    labels = []  #reset
    i = 0
    gdata = pkey.map{|x| []}

    out.puts "\\subsection{#{question[ic]}}"
    unless $no_table
      out.puts '\begin{longtable}{c'+'r'*pkey.size+'r} \hline'
      out.print "\\multicolumn{1}{p{#{item_width}mm}}{} & "
      out.print pkey.map{|val|
        "\\multicolumn{1}{p{#{width}mm}}{#{val}}"
      }.join(' & ')
      out.puts '& \multicolumn{1}{p{1cm}}{合計}\\\\ \\hline'.sjis
      out.puts '\endhead'
    end
  else
    out << empty_line  #空行
    head_line[0] = question[ic] #ヘッダ行の変更
    out << head_line  #ヘッダ行
  end

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
    # 複数意見のみ出力
    result.each do |r|
      break if r[-1] == 1
      unless $no_table
        out.print "\\multicolumn{1}{p{#{item_width}mm}}{#{r[0]}} & "
        out.puts r[1..-1].join(' & ')
        out.puts "\\\\ \\hline"
      end
      labels << r[0].utf8
      gdata.each_with_index do |x,i|
        x << r[i+1].to_f
      end
    end
    # 単独意見を抽出
    others = result.select{|x| x[-1]==1}
    if others.size == 1 then
      # 単独意見がひとつしかなければそのまま出力する
      r = others[0]
      unless $no_table
        out.print "\\multicolumn{1}{p{#{item_width}mm}}{#{r[0]}} & "
        out.puts r[1..-1].join(' & ')
        out.puts '\\\\ \hline'
      end
      labels << r[0].utf8
      gdata.each_with_index do |x,i|
        x << r[i+1].to_f
      end
    elsif others.size > 1 then
      other = others[0].map{0}
      others.each do |val|
        1.upto(other.size-1) do |i|
          other[i] += val[i]
        end
      end
      unless $no_table
        out.print "\\multicolumn{1}{p{#{item_width}mm}}{#{'その他'.sjis}} & "
        out.puts other[1..-1].join(' & ')
        out.puts "\\\\ \\hline"
      end
      labels << 'その他'
      gdata.each_with_index do |x,i|
        x << other[i+1].to_f
      end
    end
    unless $no_table
      out.puts "\\end{longtable}"
      if others.size > 1 then
        out.puts "その他内訳：".sjis
        out.puts "\\begin{multicols}{3}"
        out.puts "\\begin{itemize}"
        others.each do |val|
          out.print '\item '
          out.print val[0]
          1.upto(ncol-1) do |i|
            if val[i] == 1
              out.puts "(#{head_line[i]})"
              break
            end
          end
        end
        out.puts "\\end{itemize}"
        out.puts "\\end{multicols}"
      end
    end

    # グラフを出力する場合
    if $theme
      rows = $theme[:transpose]?(pkey.size):(labels.size)
      hbase = $theme[:normalize]?350:250
      g =apply_theme(Gruff::SideStackedBarFixed.new("2400x#{hbase+50*rows}"))
      g.title = (false)?("Question # #{ic}"):(question[ic].utf8)
      g.sort = false
      # add graph
      unless $theme[:transpose]
        # 縦横を入れ替えない場合

        if $theme[:normalize]
          sums = labels.map{0}
          labels.size.times do |i|
            sums[i] = gdata.inject(0){|a,v| a+v[i]}
          end
          rates = sums.map{|x| (x==0.0)?0:(100.0 / x)}
          gdata.each_with_index do |d,i|
            r = Array.new(d.size)
            rates.each_with_index do |y,k|
              r[k] = d[k] * y
            end
            g.data(pkey[i].utf8, r)
          end
          g.x_axis_label = "割合 (%)"
        else
          gdata.each_with_index do |d,i|
            g.data(pkey[i].utf8, d.map{|x| x.to_f})
          end
        end
        # labelの配列をハッシュに変更
        hash_label = {}
        labels.each_with_index{|x,i| hash_label[i] = x}
      else
        # 縦横を入れ替える場合
        if $theme[:normalize]
          rates = gdata.map{|x| 100.0 / x.inject{|a,b| a+b}}
          labels.each_with_index do |label,i|
            d = gdata.map{|x| x[i]}
            d.size.times do |k|
              if rates[k].finite?
                d[k] = d[k] * rates[k]
              else
                d[k] = 0.0
              end
            end
            g.data(label.utf8, d)
          end
          g.x_axis_label = "割合 (%)"
        else
          labels.each_with_index do |label,i|
            g.data(label.utf8,gdata.map{|x| x[i]})
          end
        end
      end
      #ラベルを設定
      g.labels = hash_label

      gfile = gout(ic)
      g.write(gfile) unless $no_png_out
      out.puts "\\begin{figure}[bp]" unless $no_table
      out.puts "\\begin{center}"
      out.puts "\\vfil"
      out.puts "\\includegraphics[width=#{$theme[:width]||'10in'}]{#{gfile}}"
      out.puts "\\end{center}"
      out.puts "\\end{figure}" unless $no_table
    end
    out.puts "\\clearpage" unless $no_table
  else
    # CSV output
    result.each do |r|
      out << r
    end
  end

end

if tex_out
  # output footer
  out.puts "\\end{document}"
  out.close
else
  out_io.close
end


