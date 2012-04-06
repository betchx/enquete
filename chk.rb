

# 処理対象のファイル名
$source = 'test-data.csv'

# 出力先
# 拡張子がtexの場合はTeXで，それ以外はCSVで出力する．
# nilなら引数から取得するか問い合わせる
##$output = __FILE__.sub(/\.rb$/i,".tex")  # このファイルの名前から自動作成
$output = nil  # checkのために引数から取得できる様にする．


#列番号はゼロからスタートする．
#ただし，ゼロは回答日時のため処理には用いられないので，実質1以上を指定することになる．
# nilの場合はコマンドプロンプトで問い合わせる
$column = 3

# セクションわけの設定
$sections = {
  1 => '回答者の属性について',
  7 => 'イメージについて',
  9 => 'きっかけ',
  12 => 'インターン',
  14 => '自由意見'
}

# 処理しなくてよい列を指定する．
$skips = [2,3,4]


# true にすると表とリスト(自由意見を含む)を出力しなくなる．
$no_table = false

## For work
$no_png_out = true


# タイトル
$title = "土木を学ぶ学生対象アンケート 学校別まとめ (回答割合グラフ)"
$author= "土木学会中部支部 土木分野における若手人材育成に関する検討委員会"




# 以下にマッチする質問は自由記述とみなし，
# 結果は集計せずにリストとして出力する．
FREE_TAG = [
  /自由に書いて/,
#  /その理由は/,
  /具体的に記述/,
  /上記以外にどんなものがあればよかったですか/,
  /理由・きっかけの詳細について/,
  #/なぜそう思ったのか/
]

# グラフの色の設定
require 'graff-color'


# TeXに埋め込むグラフの設定
$theme = {
  :font => './font/ipagp.ttf', #フォントファイル名
  :transpose => true, # 縦横入れ替え
  :normalize => true, # 正規化して割合で表示する
  :font_color => 'black',
  :marker_color => 'black',
  :background_colors => 'white',
  :title_font_size => 10,
  :legend_font_size => 9,
  :marker_font_size => 10,
  :colors => Gruff::Color.color_loop,
  :width => '12in'
}
