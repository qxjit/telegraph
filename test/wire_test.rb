require File.dirname(__FILE__) + "/test_helper"

module Telegraph
  class WireTest < Test::Unit::TestCase
    should "raise LineDead if other end of line goes away without notice" do
      switchboard = Switchboard.new
      operator = Operator.listen "localhost", 9999, switchboard
      begin
        t = Thread.new do
          wire = Wire.connect "localhost", 9999
          wire.send_message "hello"
          50.times do
            begin
              wire.next_message(:timeout => 2)
            rescue NoMessageAvailable
            end
          end
        end
        Thread.pass
      ensure
        begin
          message = switchboard.next_message(:timeout => 1)
        rescue NoMessageAvailable
        end

        operator.shutdown
      end

      assert_raises(LineDead) do
        t.join
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
          Wire.connect("localhost", 9999) do |wire|
            wire.send_message :ready
            wire.process_messages(:timeout => 0.1) do |message|
              messages << message
              break if messages.size >= 2
            end
          end
        end

        @operator.switchboard.process_messages(:timeout => 0.1) do |message, wire|
          assert_equal :ready, message.body
          wire.send_message "hello 1"
          wire.send_message "hello 2"
          break
        end

        t.join

        assert_equal ["hello 1", "hello 2"], messages.map {|m| m.body}
      end
    end

  end
end
