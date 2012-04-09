
require 'rubygems'
require 'gruff'
require 'side_stacked_bar_fixed'

module GraphOut
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

end
