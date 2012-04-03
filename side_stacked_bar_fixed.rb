require 'gruff'

##
# New gruff graph type added to enable sideways stacking bar charts 
# (basically looks like a x/y flip of a standard stacking bar chart)
#
# alun.eyre@googlemail.com
#
# Changed By Tanabe 2011/04/03
#
# ゼロが渡されるとグラフが左にずれてしまうバグを修正したもの

class Gruff::SideStackedBarFixed < Gruff::SideBar
  include StackedMixin

  def draw
    @has_left_labels = true
    get_maximum_by_stack
    super

    return unless @has_data

    # Setup spacing.
    #
    # Columns sit stacked.
    @bar_spacing ||= 0.9

    @bar_width = @graph_height / @column_count.to_f
    @d = @d.stroke_opacity 0.0
    height = Array.new(@column_count, 0)
    length = Array.new(@column_count, @graph_left)
    padding = (@bar_width * (1 - @bar_spacing)) / 2

    @norm_data.each_with_index do |data_row, row_index|
      @d = @d.fill data_row[DATA_COLOR_INDEX]

      data_row[DATA_VALUES_INDEX].each_with_index do |data_point, point_index|

    	  ## using the original calcs from the stacked bar chart to get the difference between
    	  ## part of the bart chart we wish to stack.
#    	  temp1 = @graph_left + (@graph_width -
#                                    data_point * @graph_width -
#                                    height[point_index]) + 1
#    	  temp2 = @graph_left + @graph_width - height[point_index] - 1
#    	  difference = temp2 - temp1
          ## mod by Tanabe ##
          difference = data_point * @graph_width #- 2
          difference = 0 if difference < 0
          ###################

        #左上の座標
        left_x = length[point_index] #+ 1
        left_y = @graph_top + (@bar_width * point_index) + padding
        # 右下の座標
        right_x = left_x + difference
        right_y = left_y + @bar_width * @bar_spacing
        if difference > 0
          # 次のデータのために保存
          length[point_index] += difference
          #height[point_index] += (data_point * @graph_width - 2)  # 不要
          @d = @d.rectangle(left_x, left_y, right_x, right_y)
        end

        # Calculate center based on bar_width and current row
        label_center = @graph_top + (@bar_width * point_index) + (@bar_width * @bar_spacing / 2.0)
        draw_label(label_center, point_index)
      end

    end

    @d.draw(@base_image)    
  end

  protected

  def larger_than_max?(data_point, index=0)
    max(data_point, index) > @maximum_value
  end

  def max(data_point, index)
    @data.inject(0) {|sum, item| sum + item[DATA_VALUES_INDEX][index]}
  end

end
