module Telegraph
  class Wire
    include Logging

    attr_reader :stream

    def self.connect(host, port)
      wire = new TCPSocket.new(host, port)
      return wire unless block_given?
      begin
        yield wire
      ensure
        wire.close
      end
    end

    def initialize(stream)
      @sequence = AckSequence.new
      @stream = stream
    end

    def close
      debug { "closing stream" }
      @stream.close
    end

    def closed?
      @stream.closed?
    end

    def send_message(body)
      Message.new(body, @sequence.next, nil).write stream
    rescue IOError, Errno::EPIPE, Errno::ECONNRESET => e
      close rescue nil
      raise LineDead, e.message
    end

    def process_messages(options = {:timeout => 0})
      yield next_message(options) while true
    rescue NoMessageAvailable
      retry
    end

    def next_message(options = {:timeout => 0})
      begin
        raise NoMessageAvailable unless IO.select [@stream], nil, nil, options[:timeout]
        return Message.read(@stream)
      rescue IOError, Errno::ECONNRESET => e
        raise LineDead, e.message
      end
    rescue LineDead
      close rescue nil
      raise
    end
  end
end
