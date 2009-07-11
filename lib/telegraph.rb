require 'socket'
require File.dirname(__FILE__) + "/telegraph/logging"
require File.dirname(__FILE__) + "/telegraph/wire"
require File.dirname(__FILE__) + "/telegraph/operator"

module Telegraph
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

  class NoMessageAvailable < StandardError; end
  class LineDead < StandardError; end
end

