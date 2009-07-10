module Telegraph
  class Wire
    include Logging

    attr_reader :stream

    def self.connect(host, port)
      new TCPSocket.new(host, port)
    end

    def initialize(stream)
      @stream = stream
    end

    def send_message(message)
      message_string = Marshal.dump(message)
      debug { "Wire#send_message: message size is #{message_string.length}" }
      @stream.write [message_string.length].pack("N") + message_string
    end

    def next_message(options = {:timeout => 0})
      raise NoMessageAvailable unless IO.select [@stream], nil, nil, options[:timeout]
      size = @stream.read(4)
      raise "connection closed" unless size
      message = @stream.read(size.unpack("N")[0])
      return Marshal.load(message)
    end
  end
end
