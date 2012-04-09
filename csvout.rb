# output with csv format for enquete result

require 'adder'

class CsvOut

  def initialize(out_file, header, key_id, sections, *rest)
    @io = open(out_file,"w")
    @out = CSV::Writer.generate(@io)
    @questions = header
    @key_id = key_id
    # 最後の改行はEXCELで開いたときにヘッダをわかりやすくするため
    @sects = sections
  end
  attr_reader :out, :head_line, :empty_line, :questions, :key_id, :pkey

  def header(ttl, ath)
    #      out << ttl
    #      out << ath
    #      out << []
  end


  def key(pkey,num)
    @pkey = pkey
    @head_line = ["",@pkey,"合計".sjis,"\n"].flatten
    @empty_line = head_line.map{ "" }
    # do nothing now
    #
    # out << ["内訳", *pkey]
    # out << num
    # out << []
  end

  def comments(ic)
    out << empty_line  #空行
    out << ["自由意見：".sjis,questions[ic]]
    out << [questions[key_id], "回答\n".sjis]
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
    head_line[0] = questions[ic] #ヘッダ行の変更
    out << head_line  #ヘッダ行
    result.each do |x|
      out << x
    end
  end
  def close
    @out.close
    @io.close
  end

  def section_check(ic)
    # do nothing now
    # TODO: セクション区切りを出力可能にする．
    # 実際にはたいした処理ではないが，リファクタリング中は変更できないので．
    # if tag = @sects[ic]
    #   out << []
    #   out << [tag]
    #   out << []
    # end
  end
end

