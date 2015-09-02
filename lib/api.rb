require "sinatra/base"
require_relative "prime_sum"

class Api < Sinatra::Base
  get "/?:count?" do
    count = params.fetch("count") { 10 }
    "The sum of the first #{count} prime numbers is: #{PrimeSum.new(count: count).compute}"
  end
end
