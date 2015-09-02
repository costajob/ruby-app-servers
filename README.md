The scope of this comparison is to figure out how modern (2015) Ruby application servers performs against a simple Sinatra Web application.

## Application
The ruby application computes the sum of the first specified prime numbers. It relies on the Ruby *Prime* library and uses internal cache to avoid repating the computation twice.

## Hardware & Tools
Test are performed by using a single device: 
* MacBook PRO 
* 2,2 GHz Intel Core i7 
* 8 GB 1333 MHz DDR3

### Client/Server Isolation
I order to simulate the host/client isolation i used a [Vagrant](https://www.vagrantup.com/) box with the following specs:
* RAM: 6GB
* vCPU: 3
* OS: ubuntu/trusty64
* Ruby MRI 2.2.2p95

### Load Tool
The [wrk](https://github.com/wg/wrk) tool was used to simulate 500 concurrent connections over 20 threads, for the duration of 30 seconds.
```
wrk -t20 -c 500 -d30s <url>
```

## Tested Application Servers
I tested against the following aplication servers in standalone configuration:
### Puma 2.13.4
```
bundle exec puma -C config/puma.rb -d
```
### Unicorn 4.9.0
```
bundle exec unicorn -c config/unicorn.rb -D
```
### Passenger 5.0.16
```
bundle exec passenger start -d
```
### Thin 1.6.3
```
bundle exec thin start -C config/thin.yml
```

## Comparative results
| App server     | Throughput (req/s) | Latency (ms) | Timeout (n/tot.req) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |           2276.13  |       16.65  |            0/68518  |
| Thin           |           1446.84  |      345.52  |           63/43553  |
| Passenger      |           1298.28  |      344.48  |          237/33637  |
| Unicorn        |            327.58  |      480.10  |           403/9861  |

## Final (personal) Thoughts

### Speed
*Puma* is the clear winner, although limited by GIL.
Both *Thin* and *Passenger* offers similar performance: reactive VS CSP paradigms ends on par here.
I found *Unicorn* a bit disappointing, at least in standalone mode.

### Consistency
*Puma* wins again: no errors and timeout are produced by the load tool.

### Dependencies
*Puma* is packaged as a *single gem*, allowing to reduce the external dependencies footprint.

### Configuration
*Passenger* default configuration takes care of spawning more processes when needed. Integration with both Nginx and Apache is a breeze.
*Passenger* and *Thin* provide commands to start and stop the server.

### Parallelism
The fact that *Puma* is so performant on MRI surprises me, and give some credit to the use of Ruby threads with the GIL too.
The *Mongrel* HTTP parser also confirms to be rock-solid (thanks [Zed](http://zedshaw.com/)).
Parallelism in MRI is possible with multi-process programming: copy-on-write offer (finally) performance on par with Python and PHP best solutions.

### Real World
In real world topics such as as *code optimization* and *organization* are far more important than concurrency paradigms.
Removing the cache and augmenting the number of primes number to compute esponentially descrese throughput.
In this regard an expressive language allows to keep codebase more extensible: try to keep state in pure functional languages and you know what i mean.
