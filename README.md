## Table of Contents
* [Scope](#scope)
  * [Primes](#primes)
  * [Ruby](#ruby)
  * [Platform](#platform)
  * [Wrk](#wrk)
* [Tested Application Servers](#tested-application-servers)
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
  * [The future](#the-future)

## Scope
The scope of this comparison is to figure out how modern Ruby application servers perform against a simple *Ruby* Web application.

### Primes
The Ruby application computes the sum of a range of prime numbers, fetched by the *Prime* standard library.  
To test how the application servers perform versus heavy computation i made the range limit configurable via an HTTP parameter.

### Ruby
Ruby 2.3 version was used.

### Platform
I registered these benchmarks with a MacBook PRO 15 late 2011 having these specs:
* OSX El Captain
* 2,2 GHz Intel Core i7 (4 cores)
* 8 GB 1333 MHz DDR3

### Wrk
I used [wrk](https://github.com/wg/wrk) as the loading tool.
I measured each application server three times, picking the best lap.  
The following script commands were used:

#### First 10 numbers
```
wrk -t 4 -c 100 -d 30s --timeout 2000 http://127.0.0.1:9292/10
```

#### Firt 10.000 numbers
```
wrk -t 4 -c 100 -d 30s --timeout 2000 http://127.0.0.1:9292/10000
```

## Tested Application Servers
I tested against the following application servers in standalone configuration:

### Puma
[Puma](http://puma.io/) is a concurrent application server crafted by Evan Phoenix.  
The original idea from Mongrel HTTP Parser was extended to make use of Ruby native threads to get a fast and really concurrent (on non-GIL Ruby implementations) application server. Puma relies on the pre-forking model to grant parallelism on MRI.

#### Bootstrap:
```
bundle exec puma -w 8 --preload -t 16:32
```

### Thin
[Thin](http://code.macournoyer.com/thin/) is a piece of software by Marc-André Cournoyer.  
Thin is the only application server that use the reactor-pattern to serve HTTP requests, being based on the Ruby [Eventmachine](https://github.com/eventmachine/eventmachine) library.

#### Bootstrap:
```
bundle exec thin start -C config/thin.yml
```

### Passenger
[Phusion Passenger](https://www.phusionpassenger.com/) is the only Ruby application server existing as a commercial solution (Enterprise version).  
Passenger is aimed to easy configuration and integration. Version 5 has been rewritten with performance as a key feature. Passenger supports both the pre-forking and request-pre-thread models, the latter is only available for the commercial version (not tested). 

#### Bootstrap:
```
bundle exec passenger start -p 9292 --disable-turbocaching --min-instances 8
```

### Unicorn
[Unicorn](http://unicorn.bogomips.org/) is an application server that takes advantage of the Ruby processing programming to elegantly delegate most of the load balancing to the underlaying operating system.

#### Bootstrap:
```
bundle exec unicorn -c config/unicorn.rb -D
```

## Roda
I run the tests by using [Roda](http://roda.jeremyevans.net/).  
Roda is a Ruby routing framework that is aimed to simplicity, reliability, extensibility and speed.  
It is based on the concept of a routing tree, allowing for a complete control over the request object at any point in the code.

## Benchmarks
Here are the benchmarks results ordered by increasing throughput.

### First 10 numbers
| App server     | Throughput (req/s) | Latency in ms (avg/stdev/max) |
| :------------- | -----------------: | ----------------------------: |
| Unicorn        |            549.11  |           33.57/16.64/152.81  |
| Thin           |           4360.51  |             22.91/3.85/69.28  |
| Passenger      |           8459.28  |             11.81/1.61/29.17  |
| Puma           |          24260.92  |             5.15/8.25/183.90  |

### First 10.000 numbers
| App server     | Throughput (req/s) | Latency in ms (avg/stdev/max) |
| :------------- | -----------------: | ----------------------------: |
| Thin           |            219.47  |           453.85/117.97/1910  |
| Unicorn        |            547.12  |          151.51/57.71/771.61  |
| Passenger      |            834.41  |           119.54/7.46/185.41  |
| Puma           |            845.05  |         134.61/116.24/913.47  |

## Considerations

### Speed
Puma outperforms other servers by a large measure: adopting both pre-forking and thread-per-request models is a win-win.  
Passenger was simply not able to perform on par with Puma for light computational requests, but is on the same boat for heavy-computational ones.  
Unicorn delivers the same performance for both light and heavy computational requests: the performance are not stellar, but quite consistent, making it a good option for deploying heavyweight (Rails) applications.  
Thin reactor-model performance are far away from Puma for both light and heavy computational requests.  

### Reliability
All the Web servers proved to be pretty reliable, but for Thin, that crashed once under heavy computational requests loading.  
Passenger has the best latency of the pack.

### Dependencies
All of the application servers, but for Unicorn, depends on the *rack* gem.  
Puma and Passenger have no other runtime dependencies.  
Unicorn and Thin depends on other two gems, in particular Thin is coupled with the heavyweight Eventmachine gem.

### Configuration
Passenger could run in production without any particular changes. Integration with both Nginx and Apache is a breeze thanks to the wizard installation.    
Passenger and Thin provide commands to start and stop the server, while Puma relies on a separate bin (pumactl).  
Unicorn configuration is the more *hardcore* of the bucket, but allows low level interaction with the application.

### The future
By supporting [CoW](https://en.wikipedia.org/wiki/Copy-on-write) Ruby application servers based the pre-forking model have finally pretty decent performance.  
*Ruby 3.0* will be aimed to be 3x faster and to offer a better concurrency model: between these two features i will pick the former, since pre-forking has proven to grant parallelism quite nicely.
