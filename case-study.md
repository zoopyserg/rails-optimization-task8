# Case Study: Optimizing Project Performance

## Introduction
In this case study, I will discuss how I applied optimization techniques learned throughout the course to a large-scale application where I significantly reduced page load times using custom profiling and optimization techniques.

## Project Overview
- **Project Description**: A comprehensive platform offering various services to users.
- **Development Duration**: Active development for over 10 years.
- **Performance Status**: Initially, the project suffered from slow page load times, especially on data-heavy pages.
- **Monitoring**: Basic monitoring was in place, but it lacked detailed performance insights.
- **My Role**: Senior Developer, working on this project for 3 years, primarily focusing on backend performance and scalability.

## Identifying the Problem
- **Issue**: One of the main pages of the application took approximately 2 minutes to load.
- **Metric**: Page load time.
- **Initial Hypothesis**: Suspected inefficient database queries, excessive object instantiation, and numerous partial renders.

## Optimization Process

### Profiling with Custom Profiler Module
To identify performance bottlenecks, I developed a custom profiling module. This module can be used anywhere in the codebase to start and stop profiling, and it generates detailed reports that can be viewed with `qcachegrind`.

### Code Optimization
1. **Database Queries**:
   - Found an SQL query that performed a search for a user 200 times and fixed it using `includes`.
   - Optimized many database requests by changing joins and adding `includes`.

2. **Rendering**:
   - Discovered that `semanticform` took 10 seconds to render due to a loop.
   - Investigated line by line by extracting Ruby code and measuring with `ruby-prof`.
   - Replaced arrays with hashes to speed up lookups.

3. **JavaScript Optimization**:
   - Noticed that the page's responsiveness was affected by heavy JavaScript using Stimulus and JQuery.
   - Initially planned to move everything to Stimulus but optimized the existing JavaScript instead.
   - Removed JQuery, rewrote some loops, and optimized JavaScript, resulting in almost instant performance.

4. **Method Optimization**:
   - Identified a very long and complex Ruby method with many hidden subqueries.
   - Optimized this method, reducing the execution time by 4 seconds.

5. **ERB Optimization**:
   - The biggest bottleneck was the ERB rendering time (8 seconds).
   - Attempted various optimizations but found limited improvements.
   - Optimized memory bloats by replacing `map` with `pluck`.

### Testing and Validation
- After each optimization, reran tests to measure the impact.
- Ensured functionality remained intact while performance improved.

## Results
- **Performance Improvement**: Page load time reduced from 2 minutes to 10 seconds (on a 600-file bulk upload).
- **Summary**:
  - Introduced `ruby-prof` and a profiler module for future development.
  - Optimized many database requests and related methods.
  - Changed how large arrays are accessed in memory.
  - Switched heavy JavaScript from JQuery to pure JavaScript and optimized it.

## Feedback Loop
- **Iteration**: Continuous profiling and optimization.
- **Metrics**: Regular monitoring of page load times to ensure sustained performance.

## Conclusion
- **Summary**: By applying performance profiling and monitoring techniques, I significantly improved the performance and reliability of the project.
- **Ongoing Optimization**: Regular monitoring and iterative optimization ensure continued performance improvements.
- **Impact**: Enhanced user experience, reduced operational costs, and improved development efficiency.

# Lecture Notes: Server Optimization

## Plan:
- Capacity Planning and Optimization
- Slimming Rails
- Fixing memory bloat
- Monitoring app servers
- Comparing app servers
- Comparing background workers
- Architecture of scalable web apps
- Case studies

## Capacity Planning and Optimization
- What load do we have?
- What load do we expect?
- Do we have enough capacity now?
- How many servers will we need in 1 year?
- How much do we spend on servers?
- Can we same money?
- Do we need load balancing?

### Load trends
- Chart of requests per minute during the day

### Expectations
- Use Google Trends to predict growth

### Master worker
- CPU is not the bottleneck.
- Usually bottleneck is how many workers can fit in master worker's server RAM.

### Watch Passenger status
- Shows how many workers, how much RAM they use, etc.

### Little's Law
**W = λ * T**
- W: number of requests in the system
- λ: arrival rate of requests
- T: average time a request spends in the system

Also you save money if you rent a server for 3 years right away.

Optimization cost should be less than optimization profits.
**E.g. if you can optimize in 1 week, and it saves money to pay back in a couple months - then it's worth it.**

## Slimming Rails

### Gemfile & Gemfile.lock audit
#### Derailed Benchmarks
  - derailed bundle:mem (disk usage)
  - derailed bundle:objects (RAM usage)
  - derailed exec perf:mem (disk usage at runtime)
  - TEST_COUNT=n derailed exec perf:mem_over_time (disk usage over time)
- Once big gems are found, they can be loaded partially, replaced with smaller gems or self-written code.
- Once real-tiime stats is present - we can see what kind of Big-O memory usage we have (constant, linear, exponential, etc.), if memory usage growth ends at some point or we have memory leaks, etc.

#### Gem bundler-leak.
Some gems may have C extensions that have memory leaks.
This GEM downloads a DB of known memory leaking gems.
Can be integrated in CI.

#### gem bundler-audit
Checks for known vulnerabilities in gems.
Also can be added to CI.

#### gem brakeman
Check the code for security vulnerabilities.
Also can be added to CI.

## Slimming Rails
### Slimming boot time of Rails

Custom require method in boot.rb.
Unnecessary heavy gems can be turned off using require: false in Gemfile.

### Extract things into engines
This engine can be installed on a separate server via load balancer.
This way rails boot time and memory footprint will be smaller.

### Extract into services
Satellite service can be written in Go, Rust, Ruby, Rails API, Sinatra, Hanami, Django, etc.
Especially useful for extracting situations when a lot of code is not related to the main business logic.

## Fixing memory bloat
Reduce memory spikes.
Aim for 300Mb RAM per instance.
Use the app for a while to see where the memory usage will stop growing.

### gem oink
Helps finding out which requests are memory hogs.

`oink log/oink.log`
`oink -r --format=v --threshold=10000 log/oink.log`

### Reload workers using passenger
- `puma-worker-killer` gem
- `unicorn-worker-killer` gem
- `passenger-memory-stats` gem
- GitLab can also restart workers

## Monitoring app servers
### New Relic (CPU, RAM, disk, network, etc.)
### Each cloud has its own monitoring tools (e.g. Heroku, Google Cloud, AWS)
### Puma monitoring with Yabeda
- `yabeda-puma-plugin` gem
- `yabeda-prometheus` gem
- plus Grafana
### Passenger monitoring
- `passenger-memory-stats` gem

## Comparing app servers
Good Rails server has to work well with 3 slow things:
- slow client requests (e.g. clients from 3G)
- slow apps (e.g. things that concume CPU - reports, etc)
- slow IO (slow DB, slow API network, etc)

#### WEBrick
- Single thread
- Gets the request fully
- Sends the response fully
- All this time isn't available for other requests

#### Thin
- Single process
- Multiple threads
- EventMachine, Reactor
- Downloads the request in parts
- Not available while Reactor is busy
- Need to program for Reactor EM to minimize Reactor busy time
- Can work with slow clients
- Cannot work with slow apps

#### Unicorn
- Multiple processes
- Single thread
- Master-worker
- Master connects incoming requests to workers
- Downloads the request fully
- Can't work with slow clients
- Can be useful if you reject slow clients via reverse proxy

#### Passenger
- Multiple processes
- Single thread
- Master-worker
- Built-in nginx
- Similar to Unicorn, but reverse-proxy is built-in

#### Passenger PRO (OK option)
- same as Passenger but has multi-threading

#### Puma (threaded only)
- Single process
- Multiple threads
- Incomming requests are handled by Reactor
- Reactor is the same thread
- Reactor (when done downloading the request) creates a thread for the request
- Automatically creates a new thread during IO
- When server is doing CPU-heavy tasks, it can be non-responsive

#### Puma (clustered) (OK option)
- Multiple processes
- Multiple threads
- Incomming requests are handled by Reactor and processed in new threads
- Downloaded requests are sent to multiple processes, each with multiple threads

### Minitest-Hell
- `minitest-hell` gem
- is designed to test if your rails app will work in multi-threaded environment (if there are no thread-safety issues)

## Comparing background workers
#### DelayedJob
- Storage: SQL
- Threaded: no
- Can benefit from IO: no
- Need thread-safe code: no

#### Resque
- Storage: Redis
- Threaded: no
- Can benefit from IO: no
- Need thread-safe code: no

#### Sidekiq
- Storage: Redis
- Threaded: yes
- Can benefit from IO: may be 10x faster
- Need thread-safe code: yes

## Postgres connections
One client = one server process.
Master process is called postgres.
It spawns new connection processes.
The bigger number of processes - the slower each process is (because of symophores and communication between processes).

### PGHero
Can show how many connections are used right now and by whom.
Based on PGHero report you can count how many connections you need and why.
It will show your app connections, connections by Graphana, workers, etc.

## Scalability summary
- Puma Clustered / Passenger PRO / Unicorn + Nginx
- Scaling instances and throughput
- Count Little's Law
- Proces more
  - add instances
  - reduce response time
  - reduce the variability of response time (narrow the histogram)
  - reduce amount of ram used (so that you can shove more workers)
- If queues are not full (< 10ms wait time) then adding workers won't help
- Remember change MAX_CONNECTIONS in Postgres if you change the number of workers

## Architecture of scalable web apps

### Demo
- Nginx (reverse proxy)
- Cluster
  - 3 rails apps
  - workers
- IO
  - elastic search
  - redis
  - postgres

### What can reverse proxy nginx do?
- Firewall
- Block by ip
- Protect from parsing, ddos, etc
- Load balancing
- Cache
- Server static
- Gzip
- Http/2 connection
- Go to rails to get responses

### Scaling when you predict high load
If from charts you know exactly the hours when you have request spikes,
you can use crontab to add additional workers or servers into the pool.

### Check if your spikes are caused by real users
It can easily be something else.

### Passenger pool size
- By default it has 20 workers
- When all 20 are busy it can spawn up to 40 workers
- So consider RAM

### Monitor free disk size, especially around new year.
