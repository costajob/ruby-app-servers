require "prime"

class PrimeSum
  def self.cache
    @cache ||= {}
  end

  def initialize(count: 10)
    @count = count.to_i
  end

  def compute(cache: false)
    return sum unless cache
    self.class.cache.fetch(@count) do
      sum.tap do |sum|
        self.class.cache[@count] = sum
      end
    end
  end

  private def sum
    Prime.take(@count).reduce(&:+)
  end
end
