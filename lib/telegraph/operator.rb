module Telegraph
  class Operator
    include Logging

    def self.listen(host, port)
      new TCPServer.new(host, port)
    end

    def initialize(socket)
      @socket = socket
    end

    def next_message(options = {:timeout => 0})
      @wire ||= Wire.new(@socket.accept)
      return @wire.next_message(options), @wire
    end
  end
end
