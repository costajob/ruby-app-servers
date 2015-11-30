require 'sinatra/base'
require 'prime_sum'

module Api
  class SinatraApp < Sinatra::Base
    get '/:count' do
      sum = PrimeSum.new(count: params['count']).compute(cache: params['cache'])
      "The sum of prime numbers is: #{sum}"
    end
  end
end
