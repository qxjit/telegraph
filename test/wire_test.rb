require File.dirname(__FILE__) + "/test_helper"

module Telegraph
  class WireTest < Test::Unit::TestCase
    should "raise LineDead if other end of line goes away without notice" do
      survivor, deceased = TwoWayPipe.pair.map {|p| Wire.new p}
      begin
        t = Thread.new do
          survivor.send_message "hello"
          50.times do
            begin
              survivor.next_message(:timeout => 2)
            rescue NoMessageAvailable
            end
          end
        end
        Thread.pass
      ensure
        assert_equal "hello", deceased.next_message(:timeout => 1).body
        deceased.close
      end

      assert_raises(LineDead) do
        t.join
      end
    end

    context "process_messages" do
      should "retrieve messages, retrying on NoMessageAvailable" do
        receiver, sender = TwoWayPipe.pair.map {|p| Wire.new p}
        messages = []
        t = Thread.new do 
          receiver.send_message :ready
          receiver.process_messages(:timeout => 0.1) do |message|
            messages << message
            break if messages.size >= 2
          end
        end

        sender.process_messages(:timeout => 0.1) do |message|
          assert_equal :ready, message.body
          sender.send_message "hello 1"
          sender.send_message "hello 2"
          break
        end

        t.join

        assert_equal ["hello 1", "hello 2"], messages.map {|m| m.body}
      end
    end

    context "ack" do
      should "track messages that need ack but have not received it" do
        wire = Wire.new(StringIO.new)
        wire.send_message :message_1, :need_ack => true
        wire.send_message :message_2, :need_ack => true

        assert_equal [:message_1, :message_2], wire.unacked_messages.map {|m| m.body}
      end

      should "not track messages that do not need ack" do
        wire = Wire.new(StringIO.new)
        wire.send_message :message_1
        wire.send_message :message_2

        assert_equal [], wire.unacked_messages.map {|m| m.body}
      end

      should "not track messages that needed ack and have received it" do
        ack_requestor, ack_sender = TwoWayPipe.pair.map {|p| Wire.new p}

        ack_requestor.send_message :message_1, :need_ack => true
        ack_requestor.send_message :message_2, :need_ack => true

        message_1 = ack_sender.next_message
        ack_sender.send_message :message_3, :ack => message_1

        assert_equal :message_3, ack_requestor.next_message.body
        assert_equal [:message_2], ack_requestor.unacked_messages.map {|m| m.body}
      end
    end
  end
end
