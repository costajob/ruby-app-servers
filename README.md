## Table of Contents
* [Scope](#scope)
* [Application](#application)
* [Hardware and Tools](#hardware-and-tools)
  * [Client Server Isolation](#client-server-isolation)
  * [Load Tool](#load-tool)
* [Tested Application Servers](#tested-application-servers)
  * [Puma 2](#puma-2)
  * [Thin 1.6](#thin-16)
  * [Passenger 5](#passenger-5)
  * [Unicorn 4.9](#unicorn-49)
* [Tested Ruby Frameworks](#tested-ruby-frameworks)
  * [Sinatra 1.4](#sinatra-14)
  * [Roda 2.8](#roda-28)
* [Comparative Numbers](#comparative-numbers)
  * [Sinatra](#sinatra)
  * [Roda](#roda)
* [Final Personal Thoughts](#final-personal-thoughts)
  * [Roda VS Sinatra](#roda-vs-sinatra)
  * [Speed](#speed)
  * [Reliability](#reliability)
  * [Dependencies](#dependencies)
  * [Configuration](#configuration)
  * [Concurrency and Parallelism](#concurrency-and-parallelism)

## Scope
The scope of this comparison is to figure out how modern Ruby application servers perform against a barebone *Ruby* Web application.

## Application
The Ruby application computes the sum of a range of prime numbers, fetched by the *Prime* standard library.
To test how the app servers perform versus heavy computation i made the range limit configurable via an HTTP parameter.
I also threw in a simple cache mechanism to simulate a reverse-proxy solution (also configurable as an HTTP parameter).

## Hardware and Tools
Test are performed by using a single device: 
* MacBook PRO 
* 2,2 GHz Intel Core i7 4CPU
* 8 GB 1333 MHz DDR3

### Client Server Isolation
I order to simulate the host/client isolation i used a [Vagrant](https://www.vagrantup.com/) box with the following specs:
* RAM: 6GB
* vCPU: 3
* OS: ubuntu/trusty64
* Ruby MRI 2.2.2p95

### Setup
Once you have downloaded Vagrant just run:
```
vagrant up
```
To install Ruby gems:
```
cd /vagrant && bundle install
```

### Load Tool
I used [wrk](https://github.com/wg/wrk) tool to simulate 500 concurrent connections over 20 threads, for the duration of 30 seconds.

## Tested Application Servers
I tested against the following application servers in standalone configuration:

### Puma 2
[Puma](http://puma.io/) is a concurrent application server coded by Evan Phoenix. The original idea from Mongrel HTTP Parser was extended to make use of Ruby native threads to get a fast and really concurrent (on non-GIL Ruby implementations) application server.

#### Start Command:
```
bundle exec puma -C config/puma.rb -d
```

### Thin 1.6
[Thin](http://code.macournoyer.com/thin/) is a piece of software by Marc-André Cournoyer. Thin is the only application server that use the reactor-pattern to serve HTTP requests, being based on the Ruby Eventmachine library.

#### Start Command:
```
bundle exec thin start -C config/thin.yml
```

### Passenger 5
[Phusion Passenger](https://www.phusionpassenger.com/) is the only Ruby application server existing as a commercial solution (Enterprise version). Passenger is aimed to easy configuration and integration. Version 5 has been rewritten with performance as a key feature. Passenger supports multi-threading (like Puma does) only for the commercial version. 

#### Start Command:
```
bundle exec passenger start -p 9292 -d
```

### Unicorn 4.9
[Unicorn](http://unicorn.bogomips.org/) is an application server that takes advantage of the Ruby processing programming to elegantly delegate most of the load balancing to the underlaying operating system. Currently (2015) is the main application server used at [github](https://github.com) as well.

#### Start Command:
```
bundle exec unicorn -c config/unicorn.rb -D
```

## Tested Ruby Frameworks
The tests has been run against two different Ruby Web frameworks.  
I did not included juggernaut solutions here (err..ails), since i prefer using micro-frameworks when possible: they offer a large degree of freedom while allowing to treat the Web as a plain integration layer (not as a core component).  
Here are the library tested:

### Sinatra 1.4
[Sinatra](http://www.sinatrarb.com/) is probably the second most used Ruby Web framework out there. It provides a thin layer over *rack* and a straight-to-the-face DSL for HTTP routing.

### Roda 2.8
[Roda](http://roda.jeremyevans.net/) is a Ruby routing framework that is aimed to simplicity, reliability, extensibility and speed. It is based on the concept of a routing tree, allowing for a complete control over the request object at any point in the code.

## Comparative Numbers

### Sinatra
#### 10 Numbers and Cache Disabled
```
wrk -t20 -c 500 -d30s http://192.168.33.22:9292/sinatra/10
```
| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |           2492.89  |       19.21  |            0/74941  |
| Thin           |           1267.16  |      392.29  |          103/38107  |
| Passenger      |           1326.65  |      258.68  |         4559/39930  |
| Unicorn        |            308.25  |      536.72  |           502/9278  |

#### 10.000 Numbers and Cache Disabled
```
wrk -t20 -c 500 -d30s http://192.168.33.22:9292/sinatra/10000
```
| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |            440.13  |      108.74  |            0/13207  |
| Thin           |            162.58  |     1240.12  |          3971/4882  |
| Passenger      |           1450.30  |      289.95  |        37517/43644  |
| Unicorn        |            105.57  |      894.73  |           739/3178  |

#### 10.000 Numbers and Cache Enabled
```
wrk -t20 -c 500 -d30s http://192.168.33.22:9292/sinatra/10000?cache=1
```
| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |           1885.25  |       25.39  |            0/56742  |
| Thin           |           1201.68  |      408.77  |          108/36149  |
| Passenger      |           1359.30  |      306.02  |         3809/40912  |
| Unicorn        |            280.25  |      580.48  |           511/8435  |

### Roda

#### 10 Numbers and Cache Disabled
```
wrk -t20 -c 500 -d30s http://192.168.33.22:9292/roda/10
```
| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |           5915.89  |        8.08  |           0/177960  |
| Thin           |           2149.52  |      235.89  |            0/64708  |
| Passenger      |           2405.82  |      110.54  |         2415/72380  |
| Unicorn        |            591.83  |      200.26  |          345/17811  |

#### 10.000 Numbers and Cache Disabled
```
wrk -t20 -c 500 -d30s http://192.168.33.22:9292/roda/10000
```
| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |            503.79  |       94.95  |            0/15158  |
| Thin           |            185.68  |        1380  |          3675/5590  |
| Passenger      |           2092.71  |      150.93  |        54915/62921  |
| Unicorn        |            305.76  |      449.55  |           113/9202  |

#### 10.000 Numbers and Cache Enabled
```
wrk -t20 -c 500 -d30s http://192.168.33.22:9292/roda/10000?cache=1
```
| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |           5312.39  |        9.12  |           0/159820  |
| Thin           |           2299.74  |      219.54  |           96/69220  |
| Passenger      |           2343.89  |       94.25  |         1117/70551  |
| Unicorn        |            574.86  |      191.06  |          230/17304  |

## Final Personal Thoughts

### Roda VS Sinatra
Roda was a real surprise for me: it's not only as pleasant as Sinatra to work with, but it is twice as faster as well (entering the realm of much faster solutions existing for other programming languages).
Once you get habit of the Roda's routing tree you'll find it much more versatile than your traditional MVC framework.

### Puma VS Thin VS Passenger VS Unicorn

#### Speed
*Puma* is the clear winner, proving to be fast and reliable.  
*Thin* comes closer, proving reactive pattern is a good option for short-living
requests.  
While *Passenger* performance are generally good, i had some reliability issues (read below).  
I found *Unicorn* performance disappointing, maybe its CSP implementation suffers the VM environment.

#### Reliability
*Puma* wins again: no errors are produced on both cached and uncached scenarios.
*Thin* is good on cached scenario, less reliable on heavy computations.
*Passenger* proves to be the less consistent on all scenarios, discarding many
requests as non-2xx/3xx (about 85% of total requests are rejected on non-cached scenario, it seems the queue limit has been reached, but unfortunately it gives no clue on how augmenting it).  
*Unicorn* is the slowest again, but pretty consistent managing non-cached scenario.

#### Dependencies
All of the application servers depend on the *rack* gem.  
That said *Puma* and *Passenger* have no other runtime dependencies, thus reducing dependencies footprint.
Both *Unicorn* and *Thin* have other two runtime dependencies, the latter using the *Eventmachine* gem to implement the reactive pattern.

#### Configuration
*Passenger* could run in production without any particular changes. Integration with both Nginx and Apache is a breeze.  
Both *Passenger* and *Thin* provide commands to start and stop the server, while *Puma* relies on a separate bin (*pumactl*).  
*Unicorn* configuration is the more *hardcore* of the bucket, but allows low level
interaction with the application.

#### Concurrency and Parallelism
The fact that *Puma* is so performant on MRI surprises me, and give some credit to the use of Ruby threads with the GIL too.  
By supporting [CoW](https://en.wikipedia.org/wiki/Copy-on-write) Ruby application servers performance is finally on par with other scripting languages best solutions.
*Ruby 3.0* will be aimed to be 3x faster and to offer a better concurrency model (by adopting actors and/or by using [pipeline parallelism](https://en.wikipedia.org/wiki/Pipeline_(computing)).   
These are good news indeed, although it has to be seen how new application servers can take advantage of this new features: right now you're confined to the Ruby one-process-per-request model.
