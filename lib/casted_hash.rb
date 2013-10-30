require "casted_hash/version"
require "equalizer"
require "active_support/hash_with_indifferent_access"

class CastedHash
  include Equalizer.new(:casted_hash)
  extend Forwardable
  def_delegators :@hash, *[:update, :keys]
  def_delegators :casted_hash, *[:values, :each, :each_pair]
  def_delegators :casted_hash, *Enumerable.public_instance_methods

  def initialize(constructor = {}, cast_proc = lambda { |x| x }, casted_keys = [])
    @hash = HashWithIndifferentAccess.new(constructor)
    @casted_keys = casted_keys.map &:to_s
    @cast_proc = cast_proc
  end

  def fetch(key, *args)
    unless (val = @hash[key]).nil?
      cast! key, val unless casted?(key)
      @hash.fetch(key, *args)
    else
      @hash.fetch(key, *args)
    end
  end

  def [](key)
    val = @hash[key]
    unless val.nil?
      cast! key, val unless casted?(key)
      @hash[key]
    end
  end

  def []=(key, value)
    uncasted! key
    @hash[key] = value
  end
  alias_method :store, :[]=

  def delete(key)
    uncasted! key
    @hash.delete(key)
  end

  def to_hash
    @hash
  end

  def merge(other)
    other = other.to_hash
    CastedHash.new(@hash.merge(other), @cast_proc, @casted_keys - other.keys.map(&:to_s))
  end

  def merge!(other)
    other = other.to_hash
    other.keys.each {| key | @casted_keys.delete key.to_s }
    @hash.merge!(other)
  end

  def casted?(key)
    @casted_keys.include?(key.to_s)
  end

  def inspect
    "#<CastedHash hash=#{@hash.keys.inject({}){|hash, (k, v)|hash.merge(k => casted?(k) ? @hash[k] : "<#{@hash[k]}>")}.inspect}>"
  end

  def casted_hash
    cast_all!
    @hash
  end

private

  def cast_all!
    @hash.each do |key, value|
      cast!(key, value) unless casted?(key)
    end
  end

  def cast!(key, value)
    value = @cast_proc.call(value)
    update key => value
    @casted_keys << key.to_s
  end

  def uncasted!(key)
    @casted_keys.delete key.to_s
  end
end