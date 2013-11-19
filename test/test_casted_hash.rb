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

    it "should not loop when refering to itself" do
      @hash = CastedHash.new({:a => 1}, lambda {|x| @hash[:a] + 1 })
      exception = assert_raises(SystemStackError) do
        @hash[:a]
      end
      assert_equal "Cannot cast value that is currently being cast", exception.message
    end

    it "should cast when expected" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      assert !hash.casted?(:a)
      assert !hash.casted?(:b)

      assert hash[:a]

      assert hash.casted?(:a)
      assert !hash.casted?(:b)
    end

    it "should respond to any? and empty?" do
      hash = CastedHash.new({}, lambda {})
      assert hash.empty?
      assert !hash.any?

      hash = CastedHash.new({:foo => "bar"}, lambda {})
      assert !hash.empty?
      assert hash.any?
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
      hash = CastedHash.new({}, lambda { |x| "foobar" })

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

    it "should delete values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      hash.delete(:b)
      assert_equal({"a" => 11}, hash.casted_hash)
    end

    describe "merge" do
      it "should merge values" do
        hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
        assert_equal 11, hash[:a]
        assert_equal 12, hash[:b]

        hash = hash.merge({:a => 3})

        assert_equal 13, hash[:a]
        assert_equal 12, hash[:b]

        assert_equal hash, hash.merge({})
      end

      it "should take over scope when merging two casted hashes" do
        hash1 = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
        hash2 = CastedHash.new({:c => 3, :d => 4}, lambda {|x| x + 100 })

        assert_equal 11, hash1[:a]
        assert_equal 12, hash1[:b]
        assert hash1.casted?(:a)
        assert hash1.casted?(:b)

        cast_proc1_object_id = hash1.cast_proc.object_id
        assert_equal [hash1.object_id], hash1.send(:raw).values.map{|v|v.casted_hash.object_id}.uniq

        hash3 = hash1.merge hash2

        assert_equal [hash3.object_id], hash3.send(:raw).values.map{|v|v.casted_hash.object_id}.uniq
        assert_equal hash3.cast_proc.object_id, cast_proc1_object_id

        assert_equal ["a", "b", "c", "d"], hash3.keys
        assert hash3.casted?(:a)
        assert hash3.casted?(:b)
        assert !hash3.casted?(:c)
        assert !hash3.casted?(:d)

        assert_equal 11, hash3[:a]
        assert_equal 12, hash3[:b]
        assert_equal 13, hash3[:c]
        assert_equal 14, hash3[:d]
      end

      it "should not cast all values when merging hashes" do
        hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
        hash = hash.merge :c => 3

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
      end
    end

    describe "merge!" do
      it "should merge! values" do
        hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
        assert_equal 11, hash[:a]
        assert_equal 12, hash[:b]

        hash.merge!({:a => 3})

        assert_equal 13, hash[:a]
        assert_equal 12, hash[:b]
      end

      it "should take over scope when merging two casted hashes" do
        hash1 = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
        hash2 = CastedHash.new({:c => 3, :d => 4}, lambda {|x| x + 100 })

        assert_equal 11, hash1[:a]
        assert_equal 12, hash1[:b]
        assert hash1.casted?(:a)
        assert hash1.casted?(:b)

        cast_proc1_object_id = hash1.cast_proc.object_id
        assert_equal [hash1.object_id], hash1.send(:raw).values.map{|v|v.casted_hash.object_id}.uniq

        hash1.merge! hash2

        assert_equal [hash1.object_id], hash1.send(:raw).values.map{|v|v.casted_hash.object_id}.uniq
        assert_equal hash1.cast_proc.object_id, cast_proc1_object_id

        assert_equal ["a", "b", "c", "d"], hash1.keys
        assert hash1.casted?(:a)
        assert hash1.casted?(:b)
        assert !hash1.casted?(:c)
        assert !hash1.casted?(:d)

        assert_equal 11, hash1[:a]
        assert_equal 12, hash1[:b]
        assert_equal 13, hash1[:c]
        assert_equal 14, hash1[:d]
      end

      it "should not cast all values when merging hashes" do
        hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
        hash.merge! :c => 3

        assert !hash.casted?(:a)
        assert !hash.casted?(:b)
        assert !hash.casted?(:c)

        other_hash = CastedHash.new({:c => 1, :d => 2}, lambda {|x| x + 10 })
        hash.merge! other_hash

        assert !hash.casted?(:a)
        assert !hash.casted?(:b)
        assert !hash.casted?(:c)
        assert !other_hash.casted?(:c)
        assert !other_hash.casted?(:d)
      end
    end

    it "should define a hash method" do
      l = lambda {|x| x + 10 }
      hash1 = CastedHash.new({:a => 1, :b => 2}, l)
      hash2 = CastedHash.new({:a => 1, :b => 2}, l)
      hash3 = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 11 })

      assert_equal hash1.hash, hash2.hash
      assert hash1.hash != hash3.hash
    end

    it "should not add all requested values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x|x})
      assert_nil hash[:undefined_key]

      assert_equal ["a", "b"], hash.keys

      assert_raises(KeyError) do
        hash.fetch('another_undefined_key')
      end

      assert_equal '123', hash.fetch('another_undefined_key', '123')
      assert_equal ["a", "b"], hash.keys
    end

  end
end