module Telegraph
  class Switchboard
    include Logging

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

    def drop_wire(wire)
      using_wires {|w| w.delete wire }
    end

    def using_wires
      @wires ||= []
      @wires_mutex ||= Mutex.new
      @wires_mutex.synchronize { yield @wires }
    end
  end
end
