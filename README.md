## Table of Contents
* [Scope](#scope)
  * [Primes](#primes)
  * [Ruby](#ruby)
* [Tested servers](#tested-servers)
  * [Puma](#puma)
  * [Passenger](#passenger)
  * [Unicorn](#unicorn)
* [Benchmarks](#benchmarks)
  * [Platform](#platform)
  * [Wrk](#wrk)
    * [No keep-alive](#no-keep-alive)
  * [Numbers](#numbers)
* [Considerations](#considerations)
  * [Speed](#speed)
  * [Memory](#memory)
  * [Dependencies](#dependencies)
  * [Configuration](#configuration)
  * [Threads vs processes](#threads-vs-processes)

## Scope
The scope of this comparison is to figure out how modern Ruby application servers perform against a simple [Rack](http://rack.github.io/) application.

### Primes
The Ruby application computes the sum of a range of prime numbers, fetched by the *Prime* standard library.  
The range of the first prime numbers to compute is configurable via a HTTP parameter to stretch computational time.  

### Ruby
Ruby 2.3 version is used for all of the tests.    
JRuby 9.1.2.0 is used to test the Puma application server in order to compare the threads-pool model versus the pre-forking one.

## Tested servers
I only focused on standalone Ruby servers solutions: no external balancers and/or reverse proxies.  
For the above reason i removed [Thin](http://code.macournoyer.com/thin/) from the pack, since it does not include a balancer for the spawned processes.
The pack includes:

### Puma
[Puma](http://puma.io/) is a concurrent application server crafted by Evan Phoenix.  
The original idea from Mongrel HTTP Parser was extended to make it compatible with Rack-era.  
Puma offers the threads-pool and the pre-forking models to grant parallelism on both MRI and JRuby.

#### Bootstrap:
```
bundle exec puma -w 8 --preload -t 16:32
jruby --server -S bundle exec puma -t 16:32
```

### Passenger
[Phusion Passenger](https://www.phusionpassenger.com/) is the only Ruby application server existing as a commercial solution (Enterprise version).  
Passenger supports both the pre-forking and threads-pool models, the latter is only available for the commercial version (not tested). 
Pre-forking automatically spawn a new process on demand (no need to specify the number of workers).

#### Bootstrap:
```
bundle exec passenger start -p 9292
```

### Unicorn
[Unicorn](http://unicorn.bogomips.org/) is an application server using the pre-forking processes model to elegantly delegate most of the load balancing to the underlaying operating system.  
It has been proved to be a reliable deployment option for large Rails application (e.g. Github).

#### Bootstrap:
```
bundle exec unicorn -c config/unicorn.rb
```

## Benchmarks

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
wrk -t 4 -c 100 -d 30s --timeout 2000 http://127.0.0.1:9292/?count=1000
```

#### No keep-alive
In order to do a fair comparison i benchmarked also by disabling HTTP keep-alive.  
This is required since Unicorn simply does not support it.

```
wrk -H "Connection: Close" -t 4 -c 100 -d 30s --timeout 2000 http://127.0.0.1:9292/?count=1000
```

### Memory
I measured memory peak consumption by using Xcode's Instruments.

### First 1000 numbers
| App server     | Throughput (req/s)   | Latency in ms (avg/stdev/max) | No keep-alive (req/s) |    RAM peak (MB) |
| :------------- | -------------------: | ----------------------------: | --------------------: | ---------------: |
| Unicorn        |              548.71  |           41.66/24.76/207.39  |               548.71  |            ~183  |
| Passenger      |            10036.23  |              9.95/1.35/36.67  |               548.63  |            ~138  |
| Puma (MRI)     |            26858.38  |             3.81/4.20/127.64  |               548.55  |            ~280  |
| Puma (JVM)     |            29059.83  |              1.05/0.56/42.86  |               538.61  |          531.69  |

## Considerations

### Speed
No crash was registered during the benchmarks.  
When HTTP pipe-lining is enabled Puma outperforms other application servers by a large margin.  
Passenger was simply not able to perform on par with Puma, although it offers better latency.  
As expected all of the application servers are in the same league when keep-alive is disabled.

### Memory
Memory consumption seems to be inversely proportional to throughput: Passenger and Unicorn are the less memory-hungry application servers, followed by Puma MRI and, with a large gap, Puma JVM.

### Dependencies
All of the application servers, but for Unicorn, depends on the Rack gem.  
Puma and Passenger have no other runtime dependencies.  

### Configuration
Passenger could run in production without any particular changes. Integration with both Nginx and Apache is a breeze thanks to the wizard installation.    
Passenger provides commands to start and stop the server, while Puma relies on a separate bin (pumactl).  
Unicorn configuration is the more *hardcore* of the bucket: it explicitly demands for a configuration file, while the rest of the pack can be configured directly by command line.

### Threads vs processes
Puma on JVM proved to be the fastest of the tested solutions, although MRI implementation is also very close in throughput.  
JRuby latency is also better than MRI, despite JVM confirmed to be a memory-hungry piece of software.
