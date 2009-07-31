require File.dirname(__FILE__) + "/test_helper"

module Telegraph
  class TelegraphTest < Test::Unit::TestCase
    context "when talking to an operator" do
      setup do
        @operator_pid = fork do
          operator = Operator.listen("localhost", 3346)
          operator.switchboard.process_messages(:timeout => 0.1) do |message, wire|
            wire.send_message Pong.new(message.body.value + 1) if message.body.is_a?(Ping)
            break if message.body == :test_done
          end
          operator.shutdown
        end
        sleep 0.25
      end

      teardown do
        Wire.connect("localhost", 3346) do |wire|
          wire.send_message :test_done
        end
        Process.wait @operator_pid
      end

      should "be able to pass a message and receive a response" do
        wire = Wire.connect("localhost", 3346)
        wire.send_message Ping.new(3)
        response = wire.next_message :timeout => 0.25
        assert_kind_of Pong, response.body
        assert_equal 4, response.body.value
      end

      should "be able to pass and receive multiple message" do
        wire = Wire.connect("localhost", 3346)
        wire.send_message Ping.new(3)
        wire.send_message Ping.new(5)
        wire.send_message Ping.new(7)
        assert_equal 4, wire.next_message(:timeout => 0.25).body.value
        assert_equal 6, wire.next_message(:timeout => 0.25).body.value
        assert_equal 8, wire.next_message(:timeout => 0.25).body.value
      end

      should "be able to handle multiple concurrent open wires" do
        threads = []

        100.times do |thread_i|
          threads << Thread.new do
            Wire.connect("localhost", 3346) do |wire|
              100.times do |pass_j|
                wire.send_message Ping.new(thread_i * 1000 + pass_j)
                Thread.pass
                begin
                  value = wire.next_message(:timeout => 0.25).body.value
                  Thread.exclusive { assert_equal(thread_i * 1000 + pass_j + 1, value) }
                rescue NoMessageAvailable
                  retry
                end
                Thread.pass
              end
            end
          end
        end
        Timeout.timeout(15) { threads.each {|t| t.join} }
      end

      should "raise NoMessageAvailable if no message is available within timeout" do
        wire = Wire.connect("localhost", 3346)
        assert_raises(NoMessageAvailable) { wire.next_message(:timeout => 0) }
      end
    end

    context "when handling errors" do
      setup do
        @operator_pid = fork do
          operator = Operator.listen("localhost", 3346)
          operator.switchboard.process_messages(:tiemout => 0.1) do |message, wire|
            case message.body
            when :die then exit!
            when :closeme then wire.close
            when :shutdown then
              operator.shutdown 
              break 
            end
          end
        end
        sleep 0.25
      end

      teardown do
        Process.kill "KILL", @operator_pid
        Process.wait @operator_pid
      end

      context "next_message" do
        should "raise LineDead on call to wire if operator killed itself" do
          wire = Wire.connect("localhost", 3346)
          wire.send_message :die
          assert_raises(LineDead) { wire.next_message(:timeout => 0.25) }
          assert_equal true, wire.closed?
        end

        should "raise LineDead on call to wire if operator was killed by another" do
          wire = Wire.connect("localhost", 3346)
          Process.kill "KILL", @operator_pid
          assert_raises(LineDead) { wire.next_message(:timeout => 0.25) }
          assert_equal true, wire.closed?
        end

        should "raise LineDead on if operator was cleanly shutdown" do
          wire = Wire.connect("localhost", 3346)
          wire.send_message :shutdown
          assert_raises(LineDead) { wire.next_message(:timeout => 0.25) }
          assert_equal true, wire.closed?
        end

        should "raise LineDead on if wire was closed by server" do
          10.times do |i|
            wire = Wire.connect("localhost", 3346)
            wire.send_message :closeme
            assert_raises(LineDead) { wire.next_message(:timeout => 0.25) }
            assert_equal true, wire.closed?
          end
        end

        should "raise LineDead on if wire was closed locally" do
          wire = Wire.connect("localhost", 3346)
          wire.close
          assert_raises(LineDead) { wire.next_message(:timeout => 1) }
          assert_equal true, wire.closed?
        end
      end

      context "send_message" do
        should "raise LineDead on call to wire if operator killed itself" do
          wire = Wire.connect("localhost", 3346)
          wire.send_message :die
          assert_raises(LineDead) { loop { wire.send_message(:foo) } }
          assert_equal true, wire.closed?
        end

        should "raise LineDead on call to wire if operator was killed by another" do
          wire = Wire.connect("localhost", 3346)
          Process.kill "KILL", @operator_pid
          assert_raises(LineDead) { loop { wire.send_message(:foo) } }
          assert_equal true, wire.closed?
        end

        should "raise LineDead on if operator was cleanly shutdown" do
          wire = Wire.connect("localhost", 3346)
          wire.send_message :shutdown
          assert_raises(LineDead) { loop { wire.send_message(:foo) } }
          assert_equal true, wire.closed?
        end

        should "raise LineDead on if wire was closed by server" do
          10.times do |i|
            wire = Wire.connect("localhost", 3346)
            wire.send_message :closeme
            assert_raises(LineDead) { loop { wire.send_message(:foo) } }
            assert_equal true, wire.closed?
          end
        end

        should "raise LineDead on if wire was closed locally" do
          wire = Wire.connect("localhost", 3346)
          wire.close
          assert_raises(LineDead) { loop { wire.send_message(:foo) } }
          assert_equal true, wire.closed?
        end
      end
    end
  end
end
