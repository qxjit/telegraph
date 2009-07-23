require File.dirname(__FILE__) + "/test_helper"

module Telegraph
  class MessageTest < Test::Unit::TestCase
    context "read/write" do
      should "be able to transfer multiple messages across a stream" do
        stream = StringIO.new
        Message.new(:message_1, 1, 2).write(stream)
        Message.new(:message_2, 2, 3).write(stream)

        stream.rewind

        message_1 = Message.read(stream)
        message_2 = Message.read(stream)

        assert_equal [:message_1, 1, 2], [message_1.body, message_1.sequence_number, message_1.sequence_ack]
        assert_equal [:message_2, 2, 3], [message_2.body, message_2.sequence_number, message_2.sequence_ack]
      end

      should "handle messages with sequence_ack nil" do
        stream = StringIO.new
        Message.new(:message, 1, nil).write(stream)
        stream.rewind
        assert_equal nil, Message.read(stream).sequence_ack
      end
    end

    context "read" do
      should "raise IOError if when reading stream with incomplete header data" do
        assert_raises IOError do
          # Message expects a header of 3 integers, not 2
          Message.read StringIO.new([0, 0].pack("NN"))
        end
      end

      should "raise IOError if at end of the stream" do
        assert_raises IOError do
          Message.read StringIO.new("")
        end
      end

      should "raise IOError if message body is not present" do
        assert_raises IOError do
          # Message header with no body
          Message.read StringIO.new([1,0,0].pack("NNN"))
        end
      end

      should "raise IOError if message in complete" do
        assert_raises IOError do
          # Header length specifies length 2, data is length 1
          Message.read StringIO.new([2,0,0].pack("NNN") + "a") 
        end
      end
    end
  end
end

