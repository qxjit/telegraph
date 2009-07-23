require File.dirname(__FILE__) + "/test_helper"

module Telegraph
  class AckSequenceTest < Test::Unit::TestCase
    context "next" do
      should "return unique threadsafe unique" do
        sequence = AckSequence.new
        numbers = []
        threads = [] 
        100.times do
          threads << Thread.new do
            1000.times do
              numbers << sequence.next
            end
          end
        end

        threads.each { |t| t.join }

        counts = numbers.inject(Hash.new(0)) { |h, i| h[i] += 1; h }
        assert_equal [], counts.select { |i, count| count > 1 }
      end
    end
  end
end

