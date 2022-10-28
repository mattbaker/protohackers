defmodule Protohacker.Mitm.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(port: port) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Protohacker.Mitm.DynamicSupervisor},
      {Protohacker.TcpListener,
       server: Protohacker.Mitm.Server,
       port: port,
       listen_opts: [packet: :line, buffer: 1024 * 1000],
       server_opts: [no_async: true]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
