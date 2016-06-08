## Table of Contents
* [Scope](#scope)
  * [Primes](#primes)
  * [Ruby](#ruby)
  * [Platform](#platform)
  * [Wrk](#wrk)
* [Tested servers](#tested-servers)
  * [Puma](#puma)
  * [Thin](#thin)
  * [Passenger](#passenger)
  * [Unicorn](#unicorn)
* [Roda](#roda)
* [Benchmarks](#benchmarks)
* [Considerations](#considerations)
  * [Speed](#speed)
  * [Reliability](#reliability)
  * [Dependencies](#dependencies)
  * [Configuration](#configuration)
  * [Threads vs processes vs reactor](#threads-vs-processes-vs-reactor)
  * [The future](#the-future)

## Scope
The scope of this comparison is to figure out how modern Ruby application servers perform against a simple *Ruby* Web application.

### Primes
The Ruby application computes the sum of a range of prime numbers, fetched by the *Prime* standard library.  
The range of the first prime numbers to compute is configurable via a HTTP parameter to stretch computational time.  

### Ruby
Ruby 2.3 version is used for all of the tests.    
JRuby 9.1.2.0 is used to test the Puma application server in order to compare the threads-pool model versus the pre-forking one.

### Platform
I registered these benchmarks with a MacBook PRO 15 late 2011 having these specs:
* OSX El Captain
* 2,2 GHz Intel Core i7 (4 cores)
* 8 GB 1333 MHz DDR3

### Wrk
I used [wrk](https://github.com/wg/wrk) as the loading tool.
I measured each application server three times, picking the best lap.  
The following script command is used:

```
wrk -t 4 -c 100 -d 30s --timeout 2000 http://127.0.0.1:9292/<first_n_primes_to_sum>
```

## Tested servers
I only focused on standalone Ruby servers solutions (no extrenal balancers and/or reverse proxies).  
The pack includes the following:

### Puma
[Puma](http://puma.io/) is a concurrent application server crafted by Evan Phoenix.  
The original idea from Mongrel HTTP Parser was extended to make it compatible with Rack-era.  
Puma offers the threads-pool and the pre-forking models to grant parallelism on both MRI and JRuby.

#### Bootstrap:
```
bundle exec puma -w 8 --preload -t 16:32
jruby -S bundle exec puma -t 32:64
```

### Thin
[Thin](http://code.macournoyer.com/thin/) is a piece of software by Marc-André Cournoyer.  
Thin is the only application server to adopt the [reactor-pattern](https://en.wikipedia.org/wiki/Reactor_pattern) to serve HTTP requests, being based on the Ruby [Eventmachine](https://github.com/eventmachine/eventmachine) gem. It also includes a threads-pool model, but is marked as experimental.  
Thin offers a cluster mode that spawn more workers by using a dedicated socket; unfortunately Thin clustering relies on an extrenal load balancer, thus being untestable in standalone mode.

#### Bootstrap:
```
bundle exec thin start -p 9292 --threaded
```

### Passenger
[Phusion Passenger](https://www.phusionpassenger.com/) is the only Ruby application server existing as a commercial solution (Enterprise version).  
Passenger is aimed to easy configuration and integration. It comes with a built in request caching (disabled on tests).  
Passenger supports both the pre-forking and threads-pool models, the latter is only available for the commercial version (not tested). 

#### Bootstrap:
```
bundle exec passenger start -p 9292 --disable-turbocaching --min-instances 8
```

### Unicorn
[Unicorn](http://unicorn.bogomips.org/) is an application server using the pre-forking processes model to elegantly delegate most of the load balancing to the underlaying operating system.  
It has been proved to be a reliable deployment option for large Rails application (e.g. Github).

#### Bootstrap:
```
bundle exec unicorn -c config/unicorn.rb
```

## Roda
The application uses [Roda](http://roda.jeremyevans.net/) to expose its API over HTTP.  
Roda is a Ruby routing framework that is aimed to simplicity, reliability, extensibility and speed.  

## Benchmarks
Here are the benchmarks results ordered by increasing throughput.

### Light computation (10 numbers)
| App server     | Throughput (req/s) | Latency in ms (avg/stdev/max) |
| :------------- | -----------------: | ----------------------------: |
| Unicorn        |            549.11  |           33.57/16.64/152.81  |
| Thin           |           4787.93  |             20.87/4.45/77.01  |
| Passenger      |           8459.28  |             11.81/1.61/29.17  |
| Puma           |          24260.92  |             5.15/8.25/183.90  |
| Puma (JRuby)   |          26389.50  |             3.53/8.41/207.55  |

### Heavy computation (10.000 numbers)
| App server     | Throughput (req/s) | Latency in ms (avg/stdev/max) |
| :------------- | -----------------: | ----------------------------: |
| Thin           |            219.47  |           453.85/117.97/1910  |
| Unicorn        |            547.12  |          151.51/57.71/771.61  |
| Passenger      |            834.41  |           119.54/7.46/185.41  |
| Puma           |            845.05  |         134.61/116.24/913.47  |
| Puma (JRuby)   |            946.52  |          94.22/126.81/847.11  |

## Considerations

### Speed
Puma outperforms other servers by a large measure: adopting both pre-forking and threads-pool models proved to be a win-win.  
Passenger was simply not able to perform on par with Puma for light computational requests, but is on the same league for heavy-computational ones.  
Unicorn performance are not stellar, but quite consistent: the throughput remains constant for both light and heavy computational requests.  
Thin reactor-model performance proves to be pretty solid for light computations. On heavy computational requests Thin simply cannot keep the pace of Passenger or Puma (but comparison is unfair).

### Reliability
All the Web servers proved to be pretty reliable, but for Thin, that crashed once under heavy computational requests loading (again it's understandable since it runs on a single process).  
Passenger recorded the best latency of the pack for both light and heavy computational requests.

### Dependencies
All of the application servers, but for Unicorn, depends on the Rack gem.  
Puma and Passenger have no other runtime dependencies.  
Unicorn and Thin depends on other two gems.  
As said Thin also need to be coupled with an external balancer (i.e. Nginx) to support clustering.

### Configuration
Passenger could run in production without any particular changes. Integration with both Nginx and Apache is a breeze thanks to the wizard installation.    
Passenger and Thin provide commands to start and stop the server, while Puma relies on a separate bin (pumactl).  
Unicorn configuration is the more *hardcore* of the bucket: it explicitly demands for a configuration file, while the rest of the pack can be configured directly by command line.

### Threads vs processes vs reactor
I was able to squeeze some throughput from Puma by using JRuby and its threads-pool model.   
Said that the performance gap of the pre-forking model is not so large on my workstation and JVM consumes much more memory than MRI processes.
I cannot judge Thin and the reactor pattern fairly, since i only tested it with one worker. Anyway i would not recommend Thin if you need an embeddable Ruby server (i will go with Puma everyday).

### The future
By supporting [CoW](https://en.wikipedia.org/wiki/Copy-on-write) Ruby application servers based the pre-forking model have finally pretty decent performance.  
*Ruby 3.0* will be aimed to be 3x faster and to offer a better concurrency model: between these two features i will pick the former, parallelism can be obtained by pre-forking in a painless way.
