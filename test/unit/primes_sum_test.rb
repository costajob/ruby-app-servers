require "test_helper"
require_relative  "../../lib/prime_sum"

describe PrimeSum do
  it 'must initialize count as an integer' do
    s = PrimeSum.new(count: "1000")
    s.instance_variable_get(:@count).must_equal 1000 
  end

  it 'must compute the sum' do
    s = PrimeSum.new()
    s.compute.must_equal 129
  end

  it 'must cache the result' do
    s = PrimeSum.new(count: 100)
    s.compute.must_equal PrimeSum.cache.fetch(100)
  end
end
