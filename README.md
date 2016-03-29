# NATS Client Benchmarks

This repository contains the code to benchmark and compare performance
of [NATS](http://nats.io) clients in different languages/frameworks.

Benchmarks for the following clients are available at this time:

* [Elixir](https://github.com/nats-io/elixir-nats)
* [Erlang](https://github.com/yuce/teacup_nats)
* [Go](https://github.com/nats-io/nats)
* [NodeJS](https://github.com/nats-io/node-nats)
* [Python (Tornado)](https://github.com/nats-io/python-nats)

All clients ran on a consumer grade laptop with Ubuntu
14.04, using the following benchmark setup:

* Stock gnatsd 0.7.2, running with default parameters
    * Host: 127.0.0.1
    * Port: 4222
    * TLS: no
* 1 publisher
* 1 subscriber
* 1_000_000 messages
* All messages had the same 16 byte subject
* All messages had the same 64 byte payload

Below is the raw results for a sample single run. Please take it with a grain
of salt. The numbers below are presented only to show the *order of magnitude*
between performance of clients. 

| Client           | Time to complete (microseconds) | Messages per second |
| ---------------- | ------------------------------: | ------------------: |
| Go               |                         917_084 |           1_090_411 |
| Node             |                       3_377_000 |             292_654 |
| Erlang           |                       8_878_089 |             112_637 |
| Elixir           |                      19_748_711 |              50_636 |
| Python (Tornado) |                      59_896_311 |              16_696 |

## Building the Benchmark Code

Benchmarks runs fine on Linux, and should run without modifications on OSX.
Other POSIX systems should be OK with no to little modifications.
If you successfully run the benchmarks on Windows, I would be happy
to update the instructions below. 

Benchmark code for clients exist in their own directories. After getting
the dependencies below, you can just run `make` in the directory corresponding
to a client.

Client dependencies:

* Elixir
    * [Erlang 18.x](http://www.erlang.org/downloads). It's pretty straightforward
    to compile Erlang from source, but Erlang Solutions provide precompiled
    packages for many systems [here](https://www.erlang-solutions.com/resources/download.html).
    * [Elixir 1.2.x](http://elixir-lang.org/install.html). It's pretty straightforward
    to compile Elixir from source, but Erlang Solutions provide precompiled
    packages for many systems [here](https://www.erlang-solutions.com/resources/download.html).
* Erlang
    * [Erlang 18.x](http://www.erlang.org/downloads). It's pretty straightforward
    to compile Erlang from source, but Erlang Solutions provide precompiled
    packages for many systems [here](https://www.erlang-solutions.com/resources/download.html).
    * [rebar3 3.x](https://github.com/erlang/rebar3/releases)
* Go
    * [Go 1.6.x](https://golang.org/dl/)
* NodeJS
    * [NodeJS 5.x](https://nodejs.org/en/download/)
* Python (Tornado)
    * [Python 2.7](https://www.python.org/downloads/). It's probably already
    installed on your system.
    * [virtualenv 1.11+](https://virtualenv.pypa.io/en/latest/index.html). It's probably
    already installed on your system or available with your package manager.

## Running the Benchmark Code

After building, just run `make run` in the directory for the corresponding
client. The output has the same format for all clients:

    1000000 917084 1090411

* Number of messages
* The time in microseconds to complete
* Messages per second

## Contributing

Pull requests are welcome for benchmark code for other clients
or fixes for current code.

## Notes

* Go benchmark code is taken and simplied from: https://github.com/nats-io/nats/blob/master/examples/nats-bench.go
* NodeJS code is taken and simplified from: https://github.com/nats-io/node-nats/blob/master/benchmark/pub_sub_perf.js
