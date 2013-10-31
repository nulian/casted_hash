require "casted_hash/version"
require "equalizer"
require "casted_hash/value"
require "active_support/hash_with_indifferent_access"

class CastedHash
  include Equalizer.new(:raw, :cast_proc)
  extend Forwardable
  attr_reader :cast_proc

  def_delegators :@hash, *[:keys, :inject, :key?, :include?]
  def_delegators :casted_hash, *[:collect]

  def initialize(constructor = {}, cast_proc = lambda { |x| x })
    @cast_proc = cast_proc
    @hash = HashWithIndifferentAccess.new(pack_hash(constructor))
  end

  def each
    @hash.each do |key, value|
      yield key, value.casted_value
    end
  end
  alias_method :each_pair, :each

  def values
    @hash.values.map(&:casted_value)
  end

  def fetch(key, *args)
    val = @hash[key]

    if val.nil?
      @hash.fetch(key, *args)
    else
      cast(key, val).value
    end
  end

  def [](key)
    val = @hash[key]
    val.casted_value unless val.nil?
  end

  def []=(key, value)
    @hash[key] = pack(value)
  end
  alias_method :store, :[]=

  def delete(key)
    @hash.delete(key)
  end

  def to_hash
    @hash
  end

  def merge(other)
    other = other.to_hash
    self.class.new(@hash.merge(other), cast_proc)
  end

  def merge!(other)
    other = pack_hash(other)
    @hash.merge!(other)
  end

  def casted?(key)
    val = @hash[key]
    val.casted? if val
  end

  def inspect
    "#<#{self.class.name} hash=#{@hash.inject({}){|hash, (k, v)|hash.merge(k => casted?(k) ? v.value : "<#{v.value}>")}}>"
  end

  def casted_hash
    cast_all!

    @hash.inject({}) do |hash, (key, value)|
      hash.merge(key => value.value)
    end
  end

private

  def raw
    @hash
  end

  def cast_all!
    @hash.each do |key, value|
      value.cast!
    end
  end

  def pack(value)
    if value.is_a?(Value)
      value
    else
      Value.new(value, cast_proc)
    end
  end

  def pack_hash(hash)
    hash.inject({}) do |hash, (key, value)|
      hash.merge key => pack(value)
    end if hash
  end
end