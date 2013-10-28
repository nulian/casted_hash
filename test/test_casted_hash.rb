require 'helper'

class TestCastedHash < Minitest::Test
  describe CastedHash do

    it "should be able to define a processor method" do
      hash = CastedHash.new({:foo => 1}, lambda { |x| x.to_s })

      hash[:bar] = 1
      assert_equal "1", hash[:bar]

      hash[:bar] = 2
      assert_equal "2", hash[:bar]

      hash.store :bar, 3
      assert_equal "3", hash[:bar]
    end

    it "should only process once" do
      hash = CastedHash.new({:foo => 1}, lambda { |x| x + 1 })

      assert_equal 2, hash[:foo]
      assert_equal 2, hash[:foo]

      hash[:bar] = 123
      assert_equal 124, hash[:bar]
      assert_equal 124, hash[:bar]
    end

    it "should be able to fetch all processed values" do
      hash = CastedHash.new({:a => 1, :b => 10, :c => 100}, lambda { |x| x * 10 })
      assert_equal [10, 100, 1000], hash.values
    end

    it "should inspect processed values" do
      hash = CastedHash.new(nil, lambda { |x| "foobar" })

      assert_equal("#<CastedHash hash={}>", hash.inspect)

      hash[:bar] = "foo"
      assert_equal("#<CastedHash hash={\"bar\"=>\"foobar\"}>", hash.inspect)

      hash = CastedHash.new({:foo => "bar"}, lambda { |x| "foobar" })
      assert_equal("#<CastedHash hash={\"foo\"=>\"foobar\"}>", hash.inspect)
    end

    it "should loop through processed values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda { |x| "processed: #{x}" })
      map = []

      hash.each do |key, value|
        map << value
      end

      assert_equal ["processed: 1", "processed: 2"], map
    end

    it "should reject processed values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda { |x| x + 10 })
      assert_equal({"b" => 12}, hash.reject {|key, value| value == 11}.to_hash)
    end

    it "should delete values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      hash.delete(:b)
      assert_equal({"a" => 11}, hash.to_hash)
    end

    it "should merge values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      assert_equal 11, hash[:a]
      assert_equal 12, hash[:b]

      hash = hash.merge({:a => 3})

      assert_equal 13, hash[:a]
      assert_equal 12, hash[:b]
    end

    it "should merge! values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      assert_equal 11, hash[:a]
      assert_equal 12, hash[:b]
      
      hash.merge!({:a => 3})

      assert_equal 13, hash[:a]
      assert_equal 12, hash[:b]
    end

  end
end