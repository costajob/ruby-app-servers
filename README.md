# Intention
The scope of this test is to figure out how current (2015) Ruby application servers performs against a simple SInatra Web application.

## Application
The ruby application is  avery simple one: it computes the sum of the first specified prime numbers. It relies on the Ruby *Prime* library.

## Hardware
Test are performed by using a single device: 
* MacBook PRO 
* 2,2 GHz Intel Core i7 
* 8 GB 1333 MHz DDR3

### Client/Server Isolation
I order to simulate the host/client isolation i used a [Vagrant](8 GB 1333 MHz DDR3) box with the following specs
* RAM: 6GB
* vCPU: 3

## SW Stack
* OS: ubuntu/trusty64
* Ruby MRI 2.2.2p95

## Load Tool
The [wrk](https://github.com/wg/wrk) tool was used for load tests. The tool simulates 500 concurremt requests on 20 threads for the duration of 30 seconds.
```
wrk -t20 -c 500 -d30s <url>
```

## Tested Application Servers
I tested against the following aplication servers in standalone configuration:
### Puma 2.13.4
```
bundle exec puma -C config/puma.rb
```
### Unicorn 4.9.0
```
bundle exec unicorn -C unicorn.rb -D
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
| Unicorn        |            327.58  |      480.10  |           403/9861  |
| Passenger      |           1298.28  |      344.48  |          237/33637  |
| Thin           |           1446.84  |      345.52  |           63/43553  |

## Final (personal) Thoughts

### Speed
*Puma* seem the clear winner here, also when not used with native-threads Ruby implementation.
Both *Thin* and *Passenger* offers similar results: reactive VS CSP paradigms ends on par here.
*Unicorn* is a bit disappointing, at least in standalone mode: i tried different configurations, but results were far behind my expectations (any suggestions are welcome).

### Dependencies
*Puma* is packaged as a *single gem*: i really like it since it allows to keep the external dependencies footprint very small compared to the aother contendants.

### Configuration
*Passenger* does not require any configuration, taking care of spawning more processes when needed. It also offers straightforward configuration with Nginx and Apache. The fact a whole team of developer worked on it is clear.
*Puma* is very esy to configure and offer very good performance without requiring specific vodoo.
*Unicorn* is a bit harder to configure to me.
*Thin* falls within *Passenger* and *Puma*: is pretty easy to configure, but some options (e.g. multiple servers) require digging deeper into its implementation.
Both *Passenger* and *Thin* offer command to start and stop the server, while the others require killing processes manually.

### Parallelism
The fact that *Puma* is so performant (also with GIL) let me think that Ruby therads offer good performance gain on non-CPU bound tasks. 
Also the HTTP parser from *Mongrel* demostrates to be rock-solid after all these years (thanks [Zed](http://zedshaw.com/)).
True parallelism is currently possible with multi-process programming in MRI: copy-on-write offer performance on par with Python and PHP best solutions.
To me topics such as as *code optimization* and *organization* are far more important than concurrency paradigms: removing tha cache from Prime numbers computaion results in esponential throughput decrease (try to keep state in [Elixir](http://elixir-lang.org/) and then tell me).
Ruby is a clear winner on this area.
