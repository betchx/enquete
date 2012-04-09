
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

