require "prime"

class PrimeSum
  def self.cache
    @cache ||= {}
  end

  def initialize(count: 10)
    @count = count.to_i
  end

  def compute
    self.class.cache.fetch(@count) do
      Prime.take(@count).reduce(&:+).tap do |sum|
        self.class.cache[@count] = sum
      end
    end
  end
end
