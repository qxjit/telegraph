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
  end
end

