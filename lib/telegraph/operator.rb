require 'thread'

module Telegraph
  class Operator
    include Logging

    attr_reader :switchboard

    def self.listen(host, port, switchboard = Switchboard.new)
      new TCPServer.new(host, port), switchboard
    end

    def initialize(socket, switchboard)
      @socket = socket
      @switchboard = switchboard
      @accept_thread = Thread.new do
        @socket.listen 100
        loop do
          client = @socket.accept
          debug { "Accepted connection: #{client.inspect}" }
          @switchboard.add_wire Wire.new(client)
        end
      end
    end

    def port
      @socket.addr[1]
    end

    def shutdown
      debug { "Shutting down" }
      begin
        @socket.close
      ensure
        @switchboard.close_all_wires
      end
    end
  end
end
