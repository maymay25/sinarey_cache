
require 'sinarey_cache/fifo/cache'

major,minor = RUBY_VERSION.split(".").map{|a| a.to_i}  
if major > 1 || (major == 1 && minor > 8)
  require "sinarey_cache/lru_redux/cache19"
else
  require "sinarey_cache/lru_redux/cache"
end

module Sinarey
  class SmartCache

    def initialize(data_size,fifo_size)
      @fifo = Sinarey::FifoCache.new(fifo_size)
      @data = Sinarey::LruCache.new(data_size)
    end

    def [](key)
      @data[key]
    end

    def fetch(key)
      if cache = @data[key]
        return cache
      else
        yield if block_given?
      end
    end

    def []=(key,val,options={})
      return @data[key] = val if options[:force]
      val,version = val,options[:uuid]
      if @fifo.member?(key)
        if version.nil?
          @data[key] = val
        elsif version!= @fifo[key]
          @fifo[key] = version
          @data[key] = val
        end
      else
        @fifo[key] = version
      end
      val
    end

    alias_method :store,:[]=

    def getset(key,options={})
      if cache = @data[key]
        return cache
      else
        store(key,yield,options) if block_given?
      end
    end

    def count
      @data.count
    end

    def delete(k)
      @fifo.delete(k)
      @data.delete(k)
    end

    def clear
      @fifo.clear
      @data.clear
    end

  end
end



