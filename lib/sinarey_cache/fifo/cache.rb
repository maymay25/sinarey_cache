module Sinarey
  class FifoCache

    def initialize(max_size)
      @max_size = max_size
      @data = {}
    end

    def max_size=(size)
      raise ArgumentError.new(:max_size) if @max_size < 1
      @max_size = size
    end

    def [](key)
      @data[key]
    end

    def fetch(key)
      @data[key] || yield if block_given?
    end

    def getset(key)
      @data[key] ||= yield
    end

    def []=(key,val)
      @data[key] = val
      @data.delete(@data.first[0]) if @data.length > @max_size
      val
    end

    alias_method :store,:[]=

    def member?(key)
      @data.member?(key)
    end

    def delete(key)
      @data.delete(key)
    end

    def clear
      @data.clear
    end

  end
end
