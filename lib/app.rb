require "prime"

module App
  extend self

  def call(env)
    req = Rack::Request.new(env)
    count = req.params["count"]
    sum = Prime.take(count.to_i).reduce(&:+)
    ['200', {'Content-Type' => 'text/plain'}, ["The sum of the first #{count} numbers is: #{sum}"]]
  end
end
