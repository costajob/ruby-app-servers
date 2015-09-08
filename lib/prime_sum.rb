require "prime"

class Cache
  def initialize; @storage = {}; end

  def fetch(key)
    @storage.fetch(key) do
      return nil unless block_given?
      yield.tap { |res| @storage[key] = res }
    end
  end
end

class PrimeSum
  def self.cache
    @cache ||= Cache::new
  end

  def initialize(count: 10)
    @count = count.to_i
  end

  def compute(cache: false)
    return sum unless cache
    self.class.cache.fetch(@count) { sum }
  end

  private def sum
    Prime.take(@count).reduce(&:+)
  end
end
