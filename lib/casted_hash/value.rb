class CastedHash
  class Value
    include Equalizer.new(:value)
    attr_reader :value

    def initialize(value, cast_proc)
      @value = value
      @cast_proc = cast_proc
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

      @value = @cast_proc.call(value)
      @casted = true
    end
  end
end