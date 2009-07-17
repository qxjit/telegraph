$LOAD_PATH << File.dirname(__FILE__) + "/../lib"
require 'test/unit'
require 'telegraph'
require 'rubygems'
require 'shoulda'

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
  end
end
