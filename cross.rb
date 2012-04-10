#! ruby
# coding: utf-8

require 'csv'
require 'arg_or_query'

# 文字エンコード処理関係
require 'nkf'

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

###############################################
## 出力関係

require 'texout'
require 'csvout'

###############################################
#主キーの列番号を問い合わせる
def query_column(head)
  ans = 0
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
    puts "入力？（空行で次の行を表示, -1：クロス集計はしない)>"
    ans = gets.to_i
  end
end

# キーが行に含まれているかどうかを判定する関数
# 複数選択の結果があるので，単純な比較ではうまくいかないため作成
# 設定ファイルで上書き可能
# TODO:メソッド名が不適切なのでリネームする
def check(value, key)
  return false if value.nil? || value.empty?
  value.split(/,/).each do |x|
    return true if x.strip == key
  end
  return false
end


#############################################################
## Main
#############################################################


# 設定を記述したファイルを指定する．
raise "設定ファイルを指定してください．" if ARGV.empty?
template_file = ARGV.shift
# 設定ファイルを読み込み
require template_file

# ソースファイル名の取得
source = $source || arg_or_query("enquate csv file", "enquate.csv","soure file")
$stderr.puts "#{source.utf8}から読み込みます"

# ファイルのオープン
f = CSV.open(source,'r')
questions = f.shift

# 主キーの列番号を取得
key_id = $column
if key_id.nil?
  if ARGV.empty?
    key_id = query_column(questions)
  else
    key_id = ARGV.shift.to_i
  end
else
  key_id = -1 if key_id == 0
end


if key_id > 0
$stderr.puts sprintf("Q%03d「%s」により分析します.",
                     key_id, questions[key_id].utf8)
end

# 列数
ncol = questions.size

#output
out_file = $output
out_file = arg_or_query("出力先（TeX/CSV）","cross_out.csv","output") if out_file.nil?

$stderr.puts "#{out_file.utf8}に結果を出力します．"


$stderr.puts "初期化中"

# default formatter
formatter = CsvOut
$graph_dir = nil

# 出力先の切り替え
case  out_file 
when /\.tex$/i
  $graph_dir = out_file.sub(/\.tex$/i,'')
  Dir.mkdir($graph_dir) unless File.directory?($graph_dir)
  formatter = TexOut::A3
end


# 削除候補
#出力先グラフファイル名を指定する
def gout(ic)
  sprintf("%s/QA-%03d.png",$graph_dir,ic)
end

#セクションの設定を取得．グローバル変数になければ引数から得る．
sec = $sections
unless sec
  sec = {}
  until ARGV.empty?
    key = ARGV.shift
    raise "セクションの設定がまちがっています" unless value = ARGV.shift
    sec[key] = value
  end
end

#タイトル他を得る
title = $title || "アンケート集計結果"
author = $author || "土木学会中部支部"

######################################################
#処理開始

$stderr.puts "アンケートデータの読み込み中"

# read  data body
body = []
f.each do |row|
  body << row
end

# 各列でキーを取得する．
all_key = [nil]  # １列目は処理しない．

1.upto(ncol-1) do |ic|
  all_key << body.map{|x| x[ic]}.compact.map{|x|
    x.split(/,/).map{|s| s.strip}
  }.flatten.sort.uniq.reject{|x| x =~ /^----/}# ----で始まるものは使わない
end

# クロス集計列ごとにデータを分類
# dataは3次元配列になっている
data = []
pkey = nil
if key_id >= 0
  pkey = all_key[key_id]
  pkey.each do |key|
    data << body.select{|x| check(x[key_id], key)}
  end
else
  pkey = ["回答数".sjis]
  data = [body.clone]
end


# 出力先を開く
out = formatter.new(out_file, questions, key_id, sec, $theme)


# ヘッダの出力
out.header(title, author)

# まず，主キーを出力する．
$stderr.puts sprintf("Key Q%03d:%s", key_id, questions[key_id].utf8) if key_id >= 0
out.key(pkey, data.map{|x| x.size} )

# スキップ対象列．省略時はスキップなし．
skips = $skips || []

# 全ての列に対して処理
1.upto(ncol-1) do |ic|

  # 主キーであればすでに出力済みなので，スキップする．
  next if ic == key_id  # skip same one

  # 指定されていればスキップする．
  next if skips.include?(ic)

  $stderr.puts sprintf("処理中：Q%03d :%s",ic, questions[ic].utf8)

  # キーの取得．事故防止のためクローン作成
  keys = all_key[ic].clone

  # セクション区切りかどうかを確認し，必要ならセクション部を出力する．
  out.section_check(ic)

  # 自由記述かどうかを判定する．
  is_free = false
  toi = utf8(questions[ic])
  FREE_TAG.each do |re|
    is_free = true if toi =~ re
  end

  #自由記述かどうかで処理を振り分け
  if is_free
    #指定されていればスキップする．
    next if $no_list

    #自由記述の場合
    out.comments(ic) do |writer|
      # キーごとに分類して出力する．
      pkey.size.times do |ikey|
        #対象を抽出
        target = data[ikey].map{|x| x[ic]}.compact
        # 出力． TeX等での出力を考慮してグループ毎に一括で出力処理
        writer.add(pkey[ikey],target) unless target.empty?
      end
    end
  else
    #通常の回答の場合．

    #キー毎に結果を修正する (クロス集計の本体部分)
    res = keys.map do |key|
      arr = data.map do |chunk|
        chunk.select{|x| check(x[ic], key)}.size
      end
      arr.unshift key
      arr
    end

    # 合計値の算出
    res.each do |arr|
      arr << arr[1..-1].inject{|r,x| x + r}
    end

    # 合計値でソート
    result =  res.sort_by{|x| -x[-1]}

    # 出力
    out.table(ic,result)
  end
end

out.close


