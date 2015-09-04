The scope of this comparison is to figure out how modern Ruby application servers perform against a barebone *Sinatra* Web application.

## Application
The ruby application computes the sum of a range of prime numbers, fetched by the *Prime* standard library.
To test how the app servers perform versus heavy computation i made the range limit configurale via an HTTP parameter.
I also throwed in a simple cache mechanism to simulate a reverse-proxy solution (also configurable as an HTTP parameter).

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
I used [wrk](https://github.com/wg/wrk) tool to simulate 500 concurrent connections over 20 threads, for the duration of 30 seconds.
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

### 10 numbers, cache disabled
| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |           1958.09  |       24.45  |            0/58891  |
| Thin           |           1267.16  |      392.29  |          103/38107  |
| Passenger      |           1326.65  |      258.68  |         4559/39930  |
| Unicorn        |            308.25  |      536.72  |           502/9278  |

### 10.000 numbers, cache disabled
| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |            440.13  |      108.74  |            0/13207  |
| Thin           |            162.58  |     1240.12  |          3971/4882  |
| Passenger      |           1450.30  |      289.95  |        37517/43644  |
| Unicorn        |            105.57  |      894.73  |           739/3178  |

### 10.000 numbers, cache enabled
| App server     | Throughput (req/s) | Latency (ms) | Req. Errors (n/tot) |
| :------------- | -----------------: | -----------: | ------------------: |
| Puma           |           1885.25  |       25.39  |            0/56742  |
| Thin           |           1201.68  |      408.77  |          108/36149  |
| Passenger      |           1359.30  |      306.02  |         3809/40912  |
| Unicorn        |            280.25  |      580.48  |           511/8435  |

## Final (personal) Thoughts

### Speed
*Puma* is the clear winner, proving to be fast and reliable.
*Thin* comes closer, proving reactive pattern is a good option.
While *Passenger* performance are generally good, i had some reliability issues (read below).
I found *Unicorn* perfromance disappointing, maybe its CSP implementation suffers the VM environment (since it relies mostly on the underneath OS for balancing).

### Reliability
*Puma* wins again: no errors are produced on both cached and uncached scenarios.
*Thin* is good on cached scenario, less reliable on heavy computations.
*Passenger* proves to be the less consistent on all scenarios, discarding many
requests as non-2xx/3xx (about 85% of total requests are rejected on non-cached scenario, it seems the queue limit has ben reached, but unfortnately it gives no clue on how augmenting it).
*Unicorn* is the slowest again, but pretty consistent managing non-cached scenario.

### Dependencies
All of the application servers depend on the *rack* gem.
That said *Puma* and *Passenger* have no other runtime dependencies, thus reducing dependencies footprint.
Both *Unicorn* and *Thin* have other two runtime dependencies, the latter using the *EventMachine* gem to implement the reactive pattern.

### Configuration
*Passenger* could run in production without any particular changes. Integration with both Nginx and Apache is a breeze.
Both *Passenger* and *Thin* provide commands to start and stop the server, while
*Puma* relies on a separate bin (*pumactl*).
*Unicorn* configuration is the more *hardcore* of the bucket, but allows low level
interaction with the application.

### Concurrency and Parallelism
The fact that *Puma* is so performant on MRI surprises me, and give some credit to the use of Ruby threads with the GIL too.
The *Mongrel* HTTP parser also confirms to be rock-solid (thanks [Zed](http://zedshaw.com/)).
By supporting [CoW](https://en.wikipedia.org/wiki/Copy-on-write) Ruby application servers performance is finally on par with *Python* and *PHP* best solutions.
*Ruby 3.0* will be aimed to offer a better concurrency model, by introducing a more abstarct solution (e.g. actors), or by using [pipeline parallelism](https://en.wikipedia.org/wiki/Pipeline_(computing)). These are good news, although i found current options fit my needs pretty well.
