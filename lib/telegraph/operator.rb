require 'thread'

module Telegraph
  class Operator
    include Logging

    def self.listen(host, port)
      new TCPServer.new(host, port)
    end

    def initialize(socket)
      @socket = socket
      @accept_thread = Thread.new do
        loop do
          client = @socket.accept
          debug { "Accepted connection: #{client.inspect}" }
          using_wires {|w| w << Wire.new(client)}
        end
      end
    end

    def next_message(options = {:timeout => 0})
      debug { "Waiting for next message on any wire" }
      wire_streams = using_wires { |wires| wires.map {|w| w.stream } }
      readers, = IO.select wire_streams.select {|s| !s.closed?}, nil, nil, options[:timeout]
      raise NoMessageAvailable unless readers
      wire = using_wires {|wires| wires.detect {|w| w.stream == readers.first} }
      return wire.next_message(options), wire
    rescue LineDead => e
      debug { "LineDead: #{e.message} while reading message from wire" }
      raise NoMessageAvailable
    end

    def shutdown
      debug { "Shutting down" }
      @socket.close
    end

    def using_wires
      @wires ||= []
      @wires_mutex ||= Mutex.new
      @wires_mutex.synchronize { yield @wires }
    end
  end
end
