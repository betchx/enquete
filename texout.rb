#! ruby
# coding:utf-8

# redirect utility class
class Adder
  def initialize(tgt, mthd)
    @out = tgt
    @mthd = mthd
  end
  def add(*args)
    @out.__send__(@mthd,*args)
  end
end

# Output Enquete results with TeX format
#

module TexOut
  class Base
    def initialize(filename, questions, pkey_id, sections, graph_theme=nil)
      raise "ファイル名エラー" unless filename =~ /\.tex$/i

      @out = open(filename, "w")

      @theme = graph_theme
      @question = questions
      @key_id = pkey_id
      @hash_label = {}
      @sec = sections
      @sec_num = sec.keys.sort
      if theme
        # workdir for graphic
        @graph_dir = filename.sub(/\.tex$/i,'')
        Dir.mkdir(graph_dir) unless File.directory?(graph_dir)
      end
    end

    # 移植しやすい様に内部専用アクセッサ？をつくっている．
    [:theme, :question, :sec, :sec_num, :hash_label, :out, :key_id, :graph_dir ].each do |x|
      attr_reader x
      #private x
    end

    # メソッドの委譲．最後には除去する予定
    def puts(*a)
      out.puts(*a)
    end
    def print(*a)
      out.print(*a)
    end
    def close
      # output footer
      out.puts "\\end{document}"
      # close IO
      out.close
    end

    ###############################
    #
    #
    def key(primary_key,nums)
      @pkey = primary_key
      @width = paper_width/(pkey.size+2)
      @item_width = @width * 1.5 + 10
      section(question[key_id]+"内訳".sjis)
      #nums = yield
      table_header
      num_out("回答数",nums, nums.inject(0){|a,b| a+b})
      table_footer

      if theme
        create_hash_label
        g = apply_theme(Gruff::SideStackedBarFixed.new(key_graph_size)) # changed from Pie
        g.title = "#{question[key_id].utf8}#{"内訳"}"
        g.labels = hash_label
        g.data("回答数",nums,'blue')
        g.hide_legend = true
        g.x_axis_label = "有効回答数"
        gfile = gout(0)
        g.write(gfile) unless $no_png_out
        out.puts <<-NNN
\\vfil
\\begin{center}
\\includegraphics[width=#{theme[:width]}]{#{gfile}}
\\end{center}
        NNN
      end
      out.puts "\\clearpage"
    end
    attr_reader :width, :item_width

    attr :no_table, true

    def section_check(ic)
      if sec_num.include?(ic)
        out.puts "\\clearpage" if no_table
        section(sec[ic].sjis)
      end
    end

    def table(ic,result)
      #reset variable
      @labels = []
      @gdata = pkey.map{[]}

      out.puts "\\subsection{#{question[ic]}}"
      add_data(result)
      if theme
        g = setup_graph(ic)
        g.title = (false)?("Question # #{ic}"):(question[ic].utf8)
        print_graph(g, gout(ic),false)
      end
      out.puts "\\clearpage" unless no_table
    end

    def transpose_gdata
      wk = gdata
      gdata = labels.map{[]}
      wk.size.times do |x|
        wk[x].size.times do |y|
          gdata[y][x] = wk[x][y]
        end
      end
      wk = @row_label
      @row_label = @col_label
      @col_label = wk
    end

    def normalize_gdata
      @ori = gdata
      sums = @row_label.map{0}
      sums.size.times do |i|
        sums[i] = gdata.inject(0){|a,v| a+v[i]}
      end
      rates = sums.map{|x| (x==0.0)?0:(100.0 / x)}
      gdata.each_with_index do |d,i|
        rates.each_with_index do |y,k|
          gdata[i][k] = d[k] * y
        end
      end
    end

    attr :labels, true
    attr :gdata, true
    private :labels=

    def setup_graph(ic)
      rows = theme[:transpose]?(pkey.size):(labels.size)
      hbase = theme[:normalize]?350:250
      g =apply_theme(Gruff::SideStackedBarFixed.new("2400x#{hbase+50*rows}"))
      g.sort = false
      @row_label = pkey
      @col_label = labels
      if theme[:transpose]
        transpose_gdata
      end
      if theme[:normalize]
        normalize_gdata
        g.x_axis_label = "割合 (%)"
      end
      gdata.each_with_index do |d,i|
        g.data(@col_label[i].utf8, d.map{|x| x.to_f})
      end
      # labelの配列をハッシュに変更
      hash_label = {}
      @row_label.each_with_index{|x,i| hash_label[i] = x}
      #ラベルを設定
      g.labels = hash_label
      return g
    end

    def add_item(r)
      cap = "\\multicolumn{1}{p{#{item_width}mm}}{#{r[0]}}"
      data_out(cap,r[1..-2],r[-1])
      if theme
        labels << r[0].utf8
        gdata.each_with_index do |x,i|
          x << r[i+1].to_f
        end
      end
    end

    def add_data(result)

      long_table_header

      # 複数意見のみ出力
      multi = result.select{|x| x[-1] > 1}
      multi.each do |r|
        add_item(r)
      end
      # 単独意見を抽出
      others = result.select{|x| x[-1]==1}
      if others.size == 1 then
        # 単独意見がひとつしかなければそのまま出力する
        add_item( others[0] )

        # 表終わり
        long_table_footer
      elsif others.size > 1 then
        other = others[0].map{0}
        others.each do |val|
          1.upto(other.size-1) do |i|
            other[i] += val[i]
          end
        end
        other[0] = "その他".sjis
        add_item( other )
        long_table_footer

        #コメント一覧を出力
        output_others(others)

      else
        long_table_footer
      end
    end

    def output_others(others)
      return if $no_table

      out.puts "その他内訳：".sjis
      out.puts "\\begin{multicols}{3}"
      out.puts "\\begin{itemize}"
      others.each do |val|
        out.print '\item '
        out.print val[0]
        #1.upto(pkey.size-1) do |i|
        pkey.each_with_index do |x,i|
          if val[i+1] == 1
            out.puts "(#{x})"
            break
          end
        end
      end
      out.puts "\\end{itemize}"
      out.puts "\\end{multicols}"
    end

    def long_table_header
      return if $no_table
      out.puts '\begin{longtable}{c'+'r'*pkey.size+'r} \hline'
      out.print "\\multicolumn{1}{p{#{item_width}mm}}{} & "
      out.print pkey.map{|val|
        "\\multicolumn{1}{p{#{width}mm}}{#{val}}"
      }.join(' & ')
      out.puts '& \multicolumn{1}{p{1cm}}{合計}\\\\ \\hline'.sjis
      out.puts '\endhead'
    end

    def long_table_footer
      out.puts '\\end{longtable}' unless no_table
    end


    def comments(ic)
      out.puts "\\subsection{#{question[ic].sjis}}"
      if no_table
        out.puts "自由意見のため，グラフはありません".sjis
      else
        out.puts '\begin{multicols}{3}'
        yield Adder.new(self,:comment_output)
        out.puts '\end{multicols}'
        out.puts '\\clearpage'
      end
    end

    def comment_output(tag, comments)
      return if comments.empty?
      out.puts "\\paragraph{#{tag}}"#}
      out.puts '\begin{itemize}'
      comments.each do |c|
        out.puts "\\item #{c}"
      end
      out.puts "\\end{itemize}"
    end

    #####################################################
    private
    def packages
      return <<-KKK
\\usepackage[left=1.5cm,top=1cm,bottom=2cm,right=1cm]{geometry}
\\usepackage{longtable}
\\usepackage[dvipdfm]{graphicx}
\\usepackage{multicol}
      KKK
    end
    def titles(title,author)
      return <<-NNN
\\title{#{title}}
\\date{\\today}
\\author{#{author}}
      NNN
    end
    def begindoc
      return <<-TTT
\\begin{document}
\\pagenumbering{roman}
\\maketitle
\\vfil

      TTT
    end
    def header(title,author)
      out.puts packages.sjis
      out.puts titles(title,author).sjis
      out.puts begindoc.sjis
      out.puts toc.sjis
      out.puts <<-QQQ
\\clearpage
\\pagenumbering{arabic}
\\setcounter{page}{1}
      QQQ
    end

    def create_hash_label
      if theme
        pkey.each_with_index do |v,i|
          hash_label[i] = v.utf8
        end
      end
    end
    def section(name)
      out.puts "\\section{#{name}}"
    end

    def table_header
      out.puts <<-KKK
\\begin{tabular}{c#{'r'*pkey.size}r} \\hline
\\multicolumn{1}{p{#{item_width}mm}}{} & 
      KKK
      out.puts pkey.map{|val|
        "\\multicolumn{1}{p{#{width}mm}}{#{val}}"
      }.join(' & ')
      out.puts '& \multicolumn{1}{p{1cm}}{合計}\\\\ \hline'.sjis
    end

    def data_out(caption, data, tail = nil)
      out.print "#{caption.sjis} & "
      out.print data.join(' & ')
      unless tail.nil?
        out.print " & #{tail}\n" 
      end
      out.puts "\\\\ \\hline\n"
    end

    def num_out(caption, data, tail = nil)
      out.print "#{caption.sjis}&"
      out.print data.join('&')
      unless tail.nil?
        out.print "& #{tail}\n" 
      end
      out.puts "\\\\ \\hline\n"
    end

    def table_footer
      out.puts "\\end{tabular}\n"
    end

    #出力先グラフファイル名を指定する
    def gout(ic)
      sprintf("%s/QA-%03d.png",graph_dir,ic)
    end

    def print_graph(g, gfile, inline = true)
      g.write(gfile) unless $no_png_out
      out.puts "\\begin{figure}[bp]" unless inline
      out.puts "\\begin{center}"
      out.puts "\\vfil"
      out.puts "\\includegraphics[width=#{theme[:width]||'10in'}]{#{gfile}}"
      out.puts "\\end{center}"
      out.puts "\\end{figure}" unless inline
    end

    attr_reader :pkey

    def apply_theme(g)
      raise unless theme
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

  class A3 < Base
    def header(title, author)
      out.puts "\\documentclass[a3paper,landscape]{jsarticle}"
      super
    end

    def paper_width
      300  # mm
    end

    def key_graph_size
      sprintf('2400x%d',600+pkey.size*50)
    end

    def toc
      return <<-"NNN"
\\begin{multicols}{2}
\\tableofcontents
\\end{multicols}
      NNN
    end

  end

=begin
  class A4 < Base
    def initialize(theme = nil)
      super
    end
    def toc
      return <<-"NNN"
\\tableofcontents
\\clearpage
\\pagenumbering{arabic}
\\setcounter{page}{1}
      NNN
  end
=end

end

