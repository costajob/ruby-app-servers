require 'test_helper'
require 'prime_sum'

describe Cache do
  let(:cache) { Cache::new }

  it 'must return nil if no value is cached and no block is passed' do
    cache.fetch(:passwd).must_be_nil
  end

  it 'must store the result into cache' do
    cache.fetch(:passwd) { 's3cr37' }
    cache.fetch(:passwd).must_equal 's3cr37'
  end
end

describe PrimeSum do
  it 'must initialize count as an integer' do
    s = PrimeSum.new(count: '1000')
    s.instance_variable_get(:@count).must_equal 1000 
  end

  it 'must compute the sum' do
    s = PrimeSum.new()
    s.compute.must_equal 129
  end

  it 'must cache the result' do
    s = PrimeSum.new(count: 100)
    s.compute(cache: true).must_equal PrimeSum.cache.fetch(100)
  end
end
