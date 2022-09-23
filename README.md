# Protohacker

Solutions for [Protohackers](https://protohackers.com) :)

## Problem -1: `lib/protohacker/tcp_listener.ex`

A generic TCP listener that passes client requests to a client "server".

Servers generally live in `lib/protohacker/*/server.ex`.

## Problem: 0 `lib/protohacker/echo/server.ex`

The [Elixir intro docs](https://elixir-lang.org/getting-started/mix-otp/task-and-gen-tcp.html) help you get started here.

I struggled at first because I was trying to use ngrok. It seems ngrok does something to your TCP traffic along the way that causes the test to fail. I had to open a port in my firewall (temporarily) and I passed the test that way. A VPS would work too.

## Problem: 1 `lib/protohacker/prime/server.ex`

The fact that gen_tcp's default buffer size is pretty low caught me, it caused big messages to get cut off. I had to make the buffer size much bigger (see `.../prime/supervisor.ex`).

I also tried out `Stream.drop_while` to do the prime checker, the algorithm was lifed from some Java solution I found online somewhere :)

I used Jason for JSON parsing.

## Problem: 2 `lib/protohacker/bank/server.ex`

Erlang/Elixir's binary pattern matching was super userful here. It made it easy to parse the messages and interpret the bytes (signed integer 32s). The [docs for binary pattern matching](https://hexdocs.pm/elixir/Kernel.SpecialForms.html#%3C%3C%3E%3E/1) are kind of hard to find.

With gen_tcp you can specify the number of bytes you want to read at a time, in our case we needed 9 bytes.

I used ETS to store the asset price entries with the timestamp as the key, with one table per client. I used matchspecs to define a match that included the max/min test. This worked pretty well and was plenty fast enough. ETS is a pretty optimized data store so I had a feeling it would handle the job.

## Problem: 3 `lib/protohacker/chat/server.ex`

I created a GenServer representing the room. This made it easy to have a central process that could control receiving and broadcasting across users as needed.

Since a process handles the messages in its process inbox sequentially it also forced async user communication to become synchronous since it was acting as a central conduit. I had a feeling this could help me avoid some race conditions so I went for it. The test didn't create the kind of load that would overwhelm this "single process architecture."
