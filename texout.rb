#! ruby
# coding:utf-8

# Output Enquete results with TeX format

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
      out.close
    end

    ###############################
    #
    #
    def key(primary_key)
      @pkey = primary_key
      @width = paper_width/(pkey.size+2)
      @item_width = @width * 1.5 + 10
      section(question[key_id]+"内訳".sjis)
      table_header
      nums = yield
      data_out("回答数",nums, nums.inject(0){|a,b| a+b})

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
      out.print "#{caption.sjis}&"
      out.print data.join('&')
      unless tail.nil?
        out.print "& #{tail}\n" 
      end
      out.puts "\\\\ \\hline\n\\end{tabular}\n"
    end


    #出力先グラフファイル名を指定する
    def gout(ic)
      sprintf("%s/QA-%03d.png",graph_dir,ic)
    end

    def print_graph(g, gfile, inline = true)
      g.write(gfile) unless $no_png_out
      out.puts "\\vfil"
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

