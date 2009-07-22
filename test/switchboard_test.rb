$LOAD_PATH << File.dirname(__FILE__) + "/../lib"
require 'test/unit'
require 'telegraph'
require 'rubygems'
require 'shoulda'
require 'timeout'

module Telegraph
  class SwitchboardTest < Test::Unit::TestCase
    context "next_message" do
      should "raise NoMessageAvailable immediately when there are no wires" do
        switchboard = Switchboard.new
        assert_raises(NoMessageAvailable) do
          Timeout.timeout(0.1) { switchboard.next_message :timeout => 5 }
        end
      end
    end

    context "process_messages" do
      setup do
        @operator = Operator.listen "localhost", 9999
      end

      teardown do
        @operator.shutdown if @operator
      end

      should "retrieve messages, retrying on NoMessageAvailable" do
        messages = []
        t = Thread.new do 
          @operator.switchboard.process_messages(:timeout => 0.1) do |message, wire|
            messages << message
            break if messages.size >= 2
          end
        end

        Wire.connect("localhost", 9999) { |w| w.send_message "hello 1" }
        Wire.connect("localhost", 9999) { |w| w.send_message "hello 2" }

        t.join

        assert_equal ["hello 1", "hello 2"], messages
      end
    end

    context "any_live_wires?" do
      setup do
        @switchboard = Switchboard.new
        @operator = Operator.listen "localhost", 9999, @switchboard
      end

      teardown do
        @operator.shutdown if @operator
      end

      should "return false if no wires are connected" do
        assert_equal false, @switchboard.any_live_wires?
      end

      should "return true if there is a live wire connected" do
        begin
          w = Wire.connect "localhost", 9999
          w.send_message :open
          @switchboard.next_message :timeout => 0.1
          assert_equal true, @switchboard.any_live_wires?
        ensure
          w.close if w
        end
      end

      should "return false if a closed wire is connected" do
        begin
          w = Wire.connect "localhost", 9999
          w.send_message :open
          @switchboard.next_message :timeout => 0.1
        ensure
          w.close if w
        end
        @switchboard.next_message :timeout => 0.1 rescue NoMessageAvailable
        assert_equal false, @switchboard.any_live_wires?
      end
    end
  end
end

