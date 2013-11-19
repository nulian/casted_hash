class CastedHash
  class Value
    include Equalizer.new(:value)
    attr_reader :value
    attr_accessor :casted_hash

    def initialize(value, casted_hash)
      @value = value
      @casted_hash = casted_hash
    end

    def casted_value
      cast!
      @value
    end

    def casted?
      !!@casted
    end

    def cast!
      return if casted?
      raise SystemStackError, "Cannot cast value that is currently being cast" if @casting

      @casting = true

      @value = casted_hash.cast_proc.call(value)
    ensure
      @casted = true
      @casting = false
    end
  end
end