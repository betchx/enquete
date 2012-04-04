module Gruff
  module Color
    Black,    White             = *%w(#000000 #FFFFFF)         # 白黒
    Gray,  Darkgray,    Dimgray = *%w(#808080 #A9A9A9 #696969) # 灰色
    Red,       Pink,    Darkred = *%w(#FF0000 #FFC0CB #8B0000) # 赤系
    Blue,   Skyblue,   Darkblue = *%w(#0000FF #87CEEB #000088) # 青系
    Green,     Lime,  Darkgreen = *%w(#008000 #00FF00 #006400) # 緑系
    Purple,  Violet,     Indigo = *%w(#800080 #EE82EE #4B0082) # 紫系
    Orange,    Gold, Darkorange = *%w(#FFa500 #FFa500 #FF8C00) # 橙系

    module_function

    # 基本的な色の繰り返しにより設定
    def color_loop
      [
        Gray,        Red,     Blue,     Green, Purple,     Orange, #基本色
        Darkgray,   Pink,  Skyblue,      Lime, Violet,       Gold, #薄め
        Dimgray, Darkred, Darkblue, Darkgreen, Indigo, Darkorange, #濃い目
      ]
    end

    def gray_scale(n = 9)
      div = 255.0 / (n-1)
      color = []
      n.times do |i|
        v = (div * i).round
        color << sprintf("#%02X%02X%02X",v,v,v)
      end
      color
    end
  end
end
