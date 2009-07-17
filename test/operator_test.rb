$LOAD_PATH << File.dirname(__FILE__) + "/../lib"
require 'test/unit'
require 'telegraph'
require 'rubygems'
require 'shoulda'

module Telegraph
  class OperatorTest < Test::Unit::TestCase
    context "port" do
      should "be accessible after operator has started" do
        begin
          operator = Operator.listen("localhost", 9999, Switchboard.new)
          assert_equal 9999, operator.port
        ensure
          operator.shutdown if operator
        end
      end
    end

    context "shutdown" do
      should "shutdown all connections on the switchboard" do
        begin
          switchboard = Switchboard.new
          operator = Operator.listen("localhost", 9999, switchboard)
          wire = Wire.connect("localhost", 9999)
        ensure
          operator.shutdown if operator
        end

        switchboard.using_wires do |wires|
          wires.each do |w|
            assert_equal true, w.closed?
          end
        end 
      end
    end
  end
end
