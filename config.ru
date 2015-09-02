require "rubygems"
require "sinatra"
require File.expand_path "../hello_primes.rb", __FILE__

run HelloPrimes::App
