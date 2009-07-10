require 'socket'
require 'logger'

module Telegraph
  module Logging
    def self.logger
      @logger ||= Logger.new($stdout)
    end
    logger.level = Logger::INFO

    def debug(&block)
      Logging.logger.debug &block
    end
  end

  class Wire
    include Logging

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
      size = @stream.read(4).unpack("N")[0]
      message = @stream.read(size)
      return Marshal.load(message)
    end
  end

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

  class Ping
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  class Pong
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  class NoMessageAvailable < Exception; end
end

