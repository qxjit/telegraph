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

    def next_message
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

    def next_message
      client = @socket.accept
      size = client.read(4).unpack("N")[0]
      debug { "Operator#next_message: message size is #{size}" }
      message = client.read(size.to_i)
      return Marshal.load(message), Wire.new(client)
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
end

