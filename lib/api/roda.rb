require 'roda'
require 'prime_sum'

module Api
  class RodaApp < Roda
    route do |r|
      r.get ':count' do |count|
        sum = PrimeSum.new(count: count).compute(cache: r['cache'])
        "The sum of numbers is: #{sum}"
      end
    end
  end
end
