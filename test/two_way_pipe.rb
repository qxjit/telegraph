class TwoWayPipe 
  def initialize(read, write)
    @read, @write = read, write
  end

  def write(*args)
    @write.write *args
  end

  def read(*args)
    @read.read(*args)
  end

  def close
    @read.close
    @write.close
  end

  def to_io
    @read
  end

  def self.pair
    rd1, wr1 = IO.pipe
    rd2, wr2 = IO.pipe

    [TwoWayPipe.new(rd1, wr2), TwoWayPipe.new(rd2, wr1)]
  end
end
