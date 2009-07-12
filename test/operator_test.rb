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
  end
end
