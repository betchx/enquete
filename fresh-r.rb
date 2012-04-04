
$source = 'new-wakate.csv'
$column = nil  # nilの場合は問い合わせる

# 出力先
# 拡張子がtexの場合はTeXで，それ以外はCSVで出力する．
# nilなら引数から取得するか問い合わせる
$output = "wakate-test-r.tex"

# TeXの場合のタイトル
$title = "若手技術者意識調査 業種別まとめ"
$author= "日建設計シビル 田辺"

# セクションわけの設定
$sections = {
  1 => '回答者の属性について',
  7 => '学生時 代のことについて',
  50=> '今現在のことについて',
}

# 以下にマッチする質問は自由記述とみなす
FREE_TAG = [
  /自由に書いて/,
  /その理由は/,
  /具体的に記述/,
  /上記以外にどんなものがあればよかったですか/,
  #/なぜそう思ったのか/
]

module Color
  black, white = *%w(#000000 #FFFFFF)
  gray, darkgray, dimgray=   *%w(#808080 #A9A9A9 #696969)
  red, pink, darkred =       *%w(#FF0000 #FFC0CB #8B0000)
  blue, skyblue, darkblue =  *%w(#0000FF #87CEEB #000088)
  green, lime, darkgreen =   *%w(#008000 #00FF00 #006400)
  purple, violet, indigo =   *%w(#800080 #EE82EE #4B0082)
  orange, gold, darkorange = *%w(#FFa500 #FFa500 #FF8C00)

$colors = [
  gray,
  red,
  blue,
  green,
  purple,
  orange,
  darkgray,
  pink,
  skyblue,
  lime,
  violet,
  gold,
  dimgray,
  darkred,
  darkblue,
  darkgreen,
  indigo,
  darkorange,
]
end

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
  :colors => $colors,
  :width => '12in'
}
