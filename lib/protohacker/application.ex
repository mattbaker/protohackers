defmodule Protohacker.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.configure(level: System.get_env("LOG_LEVEL") |> log_level())

    children = [
      {Task.Supervisor, name: Protohacker.TaskSupervisor},
      {Protohacker.TcpListener, server: Protohacker.Echo.Server, port: 3000},
      {Protohacker.TcpListener,
       server: Protohacker.Prime.Server,
       port: 3001,
       listen_opts: [packet: :line, buffer: 1024 * 1000]},
      {Protohacker.TcpListener, server: Protohacker.Bank.Server, port: 3002}
    ]

    opts = [strategy: :one_for_one, name: Protohacker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp log_level(nil), do: :info
  defp log_level(level), do: String.to_atom(level)
end
