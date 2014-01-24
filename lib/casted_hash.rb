class CastedHash < Hash
  VERSION = "0.1.4"

  def initialize(constructor = {}, cast_proc = nil)
    raise ArgumentError, "`cast_proc` required" unless cast_proc

    @cast_proc = cast_proc

    if constructor.is_a?(CastedHash)
      super()
      @casted_keys = constructor.instance_variable_get(:@casted_keys)
      regular_update(constructor)
    elsif constructor.is_a?(Hash)
      @casted_keys = []
      super()
      update(constructor)
    else
      @casted_keys = []
      super(constructor)
    end
  end

  alias_method :regular_reader, :[] unless method_defined?(:regular_reader)

  def [](key)
    cast! key
  end

  def fetch(key, *extras)
    value = cast!(key)

    if value.nil?
      super(convert_key(key), *extras)
    else
      value
    end
  end

  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)
  alias_method :regular_update, :update unless method_defined?(:regular_update)

  def []=(key, value)
    @casted_keys.delete key.to_s
    regular_writer(convert_key(key), value)
  end

  alias_method :store, :[]=

  def merge(hash)
    self.dup.update(hash)
  end

  def update(other_hash)
    return self if other_hash.empty?

    if other_hash.is_a? CastedHash
      other_hash.keys.each{|key| @casted_keys.delete key}
      super(other_hash)
    else
      other_hash.each_pair { |key, value| self[key] = value }
      self
    end
  end

  alias_method :merge!, :update

  def key?(key)
    super(convert_key(key))
  end

  alias_method :include?, :key?
  alias_method :has_key?, :key?
  alias_method :member?, :key?

  def values_at(*indices)
    indices.collect {|key| self[convert_key(key)]}
  end

  def dup
    self.class.new(self, @cast_proc)
  end

  def delete(key)
    @casted_keys.delete key.to_s
    super(convert_key(key))
  end

  def values
    cast_all!
    super
  end

  def each
    cast_all!
    super
  end

  def casted_hash
    cast_all!
    self
  end

  def casted?(key)
    @casted_keys.include?(key.to_s)
  end

protected

  def cast!(key)
    return unless key?(key)
    return regular_reader(convert_key(key)) if casted?(key)
    @casted_keys << key.to_s

    value = if @cast_proc.arity == 1
      @cast_proc.call regular_reader(convert_key(key))
    elsif @cast_proc.arity == 2
      @cast_proc.call key, regular_reader(convert_key(key))
    else
      @cast_proc.call
    end

    regular_writer(convert_key(key), value)
  end

  def cast_all!
    keys.each{|key| cast! key}
  end

  def convert_key(key)
    key.kind_of?(Symbol) ? key.to_s : key
  end

end