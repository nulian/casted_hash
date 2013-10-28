require 'helper'

class TestCastedHash < Minitest::Test
  describe CastedHash do

    it "should be able to define a cast method" do
      hash = CastedHash.new({:foo => 1}, lambda { |x| x.to_s })

      hash[:bar] = 1
      assert_equal "1", hash[:bar]

      hash[:bar] = 2
      assert_equal "2", hash[:bar]

      hash.store :bar, 3
      assert_equal "3", hash[:bar]
    end

    it "should cast when expected" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      assert !hash.casted?(:a)
      assert !hash.casted?(:b)

      assert hash[:a]

      assert hash.casted?(:a)
      assert !hash.casted?(:b)
    end

    it "should only cast once" do
      hash = CastedHash.new({:foo => 1}, lambda { |x| x + 1 })

      assert_equal 2, hash[:foo]
      assert_equal 2, hash[:foo]

      hash[:bar] = 123
      assert_equal 124, hash[:bar]
      assert_equal 124, hash[:bar]
    end

    it "should be able to fetch all casted values" do
      hash = CastedHash.new({:a => 1, :b => 10, :c => 100}, lambda { |x| x * 10 })
      assert_equal [10, 100, 1000], hash.values
    end

    it "should inspect casted values" do
      hash = CastedHash.new(nil, lambda { |x| "foobar" })

      assert_equal("#<CastedHash hash={}>", hash.inspect)

      hash[:bar] = "foo"
      assert_equal("#<CastedHash hash={\"bar\"=>\"<foo>\"}>", hash.inspect) # not yet casted
      assert_equal("foobar", hash[:bar])
      assert_equal("#<CastedHash hash={\"bar\"=>\"foobar\"}>", hash.inspect)

      hash = CastedHash.new({:foo => "bar"}, lambda { |x| "foobar" })
      assert_equal("#<CastedHash hash={\"foo\"=>\"<bar>\"}>", hash.inspect) # not yet casted
      assert_equal("foobar", hash[:foo])
      assert_equal("#<CastedHash hash={\"foo\"=>\"foobar\"}>", hash.inspect)
    end

    it "should loop through casted values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda { |x| "processed: #{x}" })
      map = []

      hash.each do |key, value|
        map << value
      end

      assert_equal ["processed: 1", "processed: 2"], map
    end

    it "should reject casted values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda { |x| x + 10 })
      assert_equal({"b" => 12}, hash.reject {|key, value| value == 11})
    end

    it "should delete values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      hash.delete(:b)
      assert_equal({"a" => 11}, hash.casted_hash)
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

    it "should not cast all values when merging hashes" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      hash = hash.merge :c => 3

      assert !hash.casted?(:a)
      assert !hash.casted?(:b)
      assert !hash.casted?(:c)

      hash.merge! :c => 3

      assert !hash.casted?(:a)
      assert !hash.casted?(:b)
      assert !hash.casted?(:c)

      other_hash = CastedHash.new({:c => 1, :d => 2}, lambda {|x| x + 10 })
      hash = hash.merge other_hash

      assert !hash.casted?(:a)
      assert !hash.casted?(:b)
      assert !hash.casted?(:c)
      assert !other_hash.casted?(:c)
      assert !other_hash.casted?(:d)

      other_hash = CastedHash.new({:c => 1, :d => 2}, lambda {|x| x + 10 })
      hash.merge! other_hash

      assert !hash.casted?(:a)
      assert !hash.casted?(:b)
      assert !hash.casted?(:c)
      assert !other_hash.casted?(:c)
      assert !other_hash.casted?(:d)
    end

    it "should define a hash method" do
      l = lambda {|x| x + 10 }
      hash1 = CastedHash.new({:a => 1, :b => 2}, l)
      hash2 = CastedHash.new({:a => 1, :b => 2}, l)
      hash3 = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 11 })

      assert_equal hash1.hash, hash2.hash
      assert hash1.hash != hash3.hash
    end

  end
end