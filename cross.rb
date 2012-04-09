#! ruby
# coding: utf-8

require 'csv'
require 'arg_or_query'
require 'nkf'
require 'rubygems'
require 'gruff'
require 'side_stacked_bar_fixed'
require 'texout'


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


def apply_theme(g)
  raise unless $theme
  theme = $theme
  g.theme = theme
  g.font = theme[:font]
  # マージンは最小限に
  g.bottom_margin = 10
  g.top_margin = 0
  g.left_margin = 0
  g.right_margin = 10
  g.title_font_size = theme[:title_font_size] || 20
  g.legend_font_size = theme[:legend_font_size]||10
  g.legend_box_size = theme[:legend_box_size] || g.legend_font_size
  g.legend_margin = theme[:legend_margin] || g.legend_font_size/4
  g.marker_font_size = theme[:marker_font_size]||10
  g
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

$stderr.puts "#{source.utf8}から読み込みます"
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

$stderr.puts sprintf("Q%03d「%s」により分析します.",
                     key_id, question[key_id].utf8)

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
  }.flatten.sort.uniq.reject{|x| x =~ /^----/}# ----で始まるものは使わない
end

$stderr.puts "アンケートデータの読み込み中"

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

$stderr.puts "#{out_file.utf8}に結果を出力します．"

# TeX出力かどうかを判定
tex_out = out_file =~ /\.tex$/i

$stderr.puts "初期化中"

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

out = nil

# 最後の改行はEXCELで開いたときにヘッダをわかりやすくするため
head_line = ["",pkey,"合計".sjis,"\n"].flatten

title = $title || "アンケート集計結果"
author = $author || "土木学会中部支部"

if tex_out
  out = TexOut::A3.new(out_file, question, key_id, sec, $theme)
else
  out_io = open(out_file,"w")
  out = CSV::Writer.generate(out_io)
  class << out
    # additional initalizer
    def setup(pkeys,kid,io,questions)
      @pkey = pkeys
      @key_id = kid
      @head_line = ["",pkeys,"合計".sjis,"\n"].flatten
      @io = io
      @question = questions
    end
    attr_reader :head_line, :empty_line, :question, :key_id
    def out
      self
    end

    def header(ttl, ath)
      @empty_line = head_line.map{ "" }
      #      out << ttl
      #      out << ath
      #      out << []
    end
    def key(pkey,num)
      # do nothing now
    end
    def comments(ic)
      out << empty_line  #空行
      out << ["自由意見：".sjis,question[ic]]
      out << [question[key_id], "回答\n".sjis]
      yield Adder.new(self, :add_comments)
    end

    def add_comments(key, *args)
      if key
        args.flatten.each do |iken|
          out << [key, iken]
        end
      end
    end

    def table(ic, result)
      out << empty_line  #空行
      head_line[0] = question[ic] #ヘッダ行の変更
      out << head_line  #ヘッダ行
      result.each do |x|
        out << x
      end
    end
    alias :original_close :close
    def close
      original_close
      @io.close
    end

    def section_check(ic)
      # do nothing now
    end
  end

  out.setup(pkey,key_id,out_io,question)
end

# output header
out.header(title, author)

# output primary keys
$stderr.puts sprintf("Key Q%03d:%s", key_id, question[key_id].utf8)
out.key(pkey, data.map{|x| x.size} )


skips = $skips || []

1.upto(ncol-1) do |ic|
  next if ic == key_id  # skip same one

  # skip if specified
  next if skips.include?(ic)

  $stderr.puts sprintf("処理中：Q%03d :%s",ic, question[ic].utf8)
  keys = all_key[ic].clone
  toi = utf8(question[ic])

  is_free = false
  FREE_TAG.each do |re|
    is_free = true if toi =~ re
  end

  out.section_check(ic)


  if is_free
    out.comments(ic) do |writer|
    # loop
    pkey.size.times do |ikey|
      target = data[ikey].map{|x| x[ic]}.compact
      writer.add(pkey[ikey],target) unless target.empty?
    end
    end
  else

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

    # output
    out.table(ic,result)

=begin
      # グラフを出力する場合
      if $theme
        rows = $theme[:transpose]?(pkey.size):(labels.size)
        hbase = $theme[:normalize]?350:250
        g =apply_theme(Gruff::SideStackedBarFixed.new("2400x#{hbase+50*rows}"))
        g.title = (false)?("Question # #{ic}"):(question[ic].utf8)
        g.sort = false
        @row = 
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
            rates = gdata.map{|x| 100.0 / x.inject(0.0){|a,b| a+b}}
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
=end

  end
end

out.close


