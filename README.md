# Protohacker

Solutions for [Protohackers](https://protohackers.com) :)

## Problem -1: `lib/protohacker/tcp_server.ex`

A generic TCP server that passes client requests to a client handler.

Client handlers generally in `lib/protohacker/*/client_handler`.

## Problem: 0 `lib/protohacker/echo/client_handler.ex`

The [Elixir intro docs](https://elixir-lang.org/getting-started/mix-otp/task-and-gen-tcp.html) help you get started here.

I struggled at first because I was trying to use ngrok. It seems ngrok does something to your TCP traffic along the way that causes the test to fail. I had to open a port in my firewall (temporarily) and I passed the test that way. A VPS would work too.

## Problem: 1 `lib/protohacker/prime/client_handler.ex`

The fact that gen_tcp's default buffer size is pretty low caught me, it caused big messages to get cut off. I had to make the buffer size much bigger (see `.../prime/supervisor.ex).

I also tried out `Stream.drop_while` to do the prime checker, the algorithm was lifed from some Java solution I found online somewhere :)

## Problem: 2 `lib/protohacker/bank/client_handler.ex`

Erlang/Elixir's binary pattern matching was super userful here. It made it easy to parse the messages and interpret the bytes (signed integer 32s). The [docs for binary pattern matching](https://hexdocs.pm/elixir/Kernel.SpecialForms.html#%3C%3C%3E%3E/1) are kind of hard to find.

With gen_tcp you can specify the number of bytes you want to read at a time, in our case we needed 9 bytes.

I used ETS to store the asset price entries with the timestamp as the key, with one table per client. I uses matchspecs to define a match that included the max/min test. This worked pretty well and was plenty fast enough. ETS is a pretty optimized data store so I had a feeling it would handle the job.

I used Jason for JSON parsing.
