require 'thread'

module Telegraph
  class Operator
    include Logging

    def self.listen(host, port, switchboard)
      new TCPServer.new(host, port), switchboard
    end

    def initialize(socket, switchboard)
      @socket = socket
      @accept_thread = Thread.new do
        loop do
          client = @socket.accept
          debug { "Accepted connection: #{client.inspect}" }
          switchboard.using_wires {|w| w << Wire.new(client)}
        end
      end
    end

    def shutdown
      debug { "Shutting down" }
      @socket.close
    end
  end
end
