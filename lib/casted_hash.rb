require "casted_hash/version"
require "equalizer"
require "casted_hash/value"
require "active_support/hash_with_indifferent_access"

class CastedHash
  include Equalizer.new(:raw, :cast_proc)
  extend Forwardable
  attr_reader :cast_proc

  def_delegators :@hash, *[:keys, :inject, :key?, :include?, :empty?, :any?]
  def_delegators :casted_hash, *[:collect, :reject]

  def initialize(constructor = {}, cast_proc = nil)
    raise ArgumentError, "`cast_proc` required" unless cast_proc

    @cast_proc = cast_proc

    if constructor.is_a?(Hash)
      @hash = HashWithIndifferentAccess.new
      update(constructor)
    elsif constructor.is_a?(CastedHash)
      @hash = constructor.pack_hash(self)
    else
      raise ArgumentError
    end
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

  def pack_hash(casted_hash)
    @hash.inject(HashWithIndifferentAccess.new) do |hash, (key, value)|
      hash.merge key => pack(value, casted_hash)
    end
  end

  def update(other_hash)
    return unless other_hash.any?

    if other_hash.is_a? CastedHash
      @hash.update other_hash.pack_hash(self)
    else
      other_hash.each_pair { |key, value| store(key, value) }
    end

    self
  end

  def merge(other)
    self.dup.update other
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

  def dup
    self.class.new(self, @cast_proc)
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

  def pack(value, casted_hash = self)
    if value.is_a?(Value)
      value.casted_hash =  casted_hash
      value
    else
      Value.new(value, casted_hash)
    end
  end

end