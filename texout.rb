#! ruby
# coding:utf-8

# Output Enquete results with TeX format

module TexOut
  class Base
    def initialize(filename,graph_theme=nil)
      @theme = graph_theme
      raise "ファイル名エラー" unless filename =~ /\.tex$/i
      @out = open(filename, "w")
    end
    attr :theme
    attr :out
    private :out

    def puts(*a)
      out.puts(*a)
    end
    def print(*a)
      out.print(*a)
    end
    def close
      out.close
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
  end

  class A3 < Base
    # 初期化
    def initialize(filename, theme = nil)
      super
    end

    def header(title, author)
      out.puts "\\documentclass[a3paper,landscape]{jsarticle}"
      super
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

