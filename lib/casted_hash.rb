require "casted_hash/version"
require "equalizer"
require "active_support/hash_with_indifferent_access"

class CastedHash
  include Equalizer.new(:to_hash)
  extend Forwardable
  def_delegators :@hash, *[:update]
  def_delegators :to_hash, *[:values, :each, :each_pair, :keys]
  def_delegators :to_hash, *Enumerable.public_instance_methods

  def initialize(constructor = {}, cast_proc = lambda { |x| x }, casted_keys = [])
    @hash = HashWithIndifferentAccess.new(constructor)
    @casted_keys = casted_keys.map &:to_s
    @cast_proc = cast_proc
  end

  def fetch(key, *args)
    cast! key, @hash.fetch(key, *args) unless casted?(key)
    @hash.fetch(key, *args)
  end

  def [](key)
    cast! key, @hash[key] unless casted?(key)
    @hash[key]
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
    cast_all!
    Hash.new.merge!(@hash)
  end

  def merge(other)
    CastedHash.new(@hash.merge(other), @cast_proc, @casted_keys - other.keys.map(&:to_s))
  end

  def merge!(other)
    other.keys.each {| key | @casted_keys.delete key.to_s }
    @hash.merge!(other)
  end

private

  def casted?(key)
    @casted_keys.include?(key.to_s)
  end

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