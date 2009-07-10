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
end
