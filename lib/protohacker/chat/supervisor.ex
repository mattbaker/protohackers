defmodule Protohacker.Chat.Supervisor do
  # Automatically defines child_spec/1
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(port: port) do
    children = [
      {Protohacker.Chat.Room, []},
      {Protohacker.TcpListener,
       server: Protohacker.Chat.Server,
       port: port,
       listen_opts: [packet: :line, buffer: 1024 * 1000]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
