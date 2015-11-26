require 'sinatra/base'
require 'prime_sum'

module Api
  class SinatraApp < Sinatra::Base
    get '/?:count?' do
      count = params.fetch('count') { 10 }
      sum = PrimeSum.new(count: count).compute(cache: params['cache'])
      "The sum of the first #{count} prime numbers is: #{sum}"
    end
  end
end
