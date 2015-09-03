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

## Comparative Numbers
These are the benchmarking results of computing the sum of the first 10K primes numbers with the internal **cache enabled**:

| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |           1885.25  |       25.39  |            0/56742  |
| Thin           |           1201.68  |      408.77  |          108/36149  |
| Passenger      |           1359.30  |      306.02  |         3809/40912  |
| Unicorn        |            280.25  |      580.48  |           511/8435  |

Here are the same numbers but with internal **cache disabled**:

| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |            440.13  |      108.74  |            0/13207  |
| Thin           |            162.58  |     1240.12  |          3971/4882  |
| Passenger      |           1450.30  |      289.95  |        37517/43644  |
| Unicorn        |            105.57  |      894.73  |           739/3178  |

## Final (personal) Thoughts

### Speed
*Puma* is the clear winner, proving to be fast and reliable.
Both *Thin* and *Passenger* offer similar performance, demonstrating both reactive and CSP paradigms are valid alternatives.
I found *Unicorn* a bit disappointing, maybe its CSP implementation suffers the VM environment.

### Consistency
*Puma* wins again: no errors are produced on both cached and uncached scenarios.
*Unicorn* is far slower, but pretty consistent on managing intensive computation.
*Thin* and *Passenger* reject many requests, the latter very quickly.

### Dependencies
*Puma* is packaged as a *single gem*, allowing to reduce the external dependencies footprint.
*Thin* is the havier of the bucket, depending on the *EventMachine* gem.

### Configuration
*Passenger* default configuration takes care of spawning more processes when needed. Integration with both Nginx and Apache is a breeze.
*Passenger* and *Thin* provide commands to start and stop the server.
*Puma* and *Unicorn* configurations are more hard-coded, but the former allows all of
the options to be specified on the CLI.

### Parallelism
The fact that *Puma* is so performant on MRI surprises me, and give some credit to the use of Ruby threads with the GIL too.
The *Mongrel* HTTP parser also confirms to be rock-solid (thanks [Zed](http://zedshaw.com/)).
Parallelism in MRI is possible with multi-process programming: copy-on-write offer (finally) performance on par with Python and PHP best solutions.

### Real World
In real world topics such as as *code optimization* and *organization* are far more important than concurrency paradigms.
Removing the cache and augmenting the number of primes number to compute esponentially descrese throughput.
In this regard Ruby proves to be expressive and extensible, a severe tradeoff to consider when opting for stateless, highly concurrent functional languages.
