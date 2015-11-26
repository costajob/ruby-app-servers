require 'roda'
require 'prime_sum'

module Api
  class RodaApp < Roda
    route do |r|
      r.get ':count' do |count|
        count = count || 10
        sum = PrimeSum.new(count: count).compute(cache: r['cache'])
        "The sum of the first #{count} prime numbers is: #{sum}"
      end
    end
  end
end
