$LOAD_PATH << File.dirname(__FILE__) + "/../lib"
require 'test/unit'
require 'telegraph'
require 'rubygems'
require 'shoulda'

module Telegraph
  class TelegraphTest < Test::Unit::TestCase
    context "when talking to an operator" do
      setup do
        @operator_pid = fork do
          operator = Operator.listen("localhost", 3346)
          loop do
            begin
              message, wire = operator.next_message :timeout => 0.25
              if message.is_a?(Ping)
                wire.send_message Pong.new(message.value + 1)
              end
            rescue NoMessageAvailable
              break
            end
          end
        end
        sleep 0.25
      end

      teardown do
        Process.kill "TERM", @operator_pid
        Process.wait @operator_pid
      end

      should "be able to pass a message and receive a response" do
        wire = Wire.connect("localhost", 3346)
        wire.send_message Ping.new(3)
        response = wire.next_message :timeout => 0.25
        assert_kind_of Pong, response
        assert_equal 4, response.value
      end

      should "be able to pass and receive multiple message" do
        wire = Wire.connect("localhost", 3346)
        wire.send_message Ping.new(3)
        wire.send_message Ping.new(5)
        wire.send_message Ping.new(7)
        assert_equal 4, wire.next_message(:timeout => 0.25).value
        assert_equal 6, wire.next_message(:timeout => 0.25).value
        assert_equal 8, wire.next_message(:timeout => 0.25).value
      end

      should "raise NoMessageAvailable if no message is available within timeout" do
        wire = Wire.connect("localhost", 3346)
        assert_raises(NoMessageAvailable) { wire.next_message(:timeout => 0) }
      end
    end
  end
end
