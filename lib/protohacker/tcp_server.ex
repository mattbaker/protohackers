defmodule Protohacker.TcpListener do
  require Logger

  def start_link(opts) do
    server = Keyword.fetch!(opts, :server)
    port = Keyword.fetch!(opts, :port)
    custom_opts = Keyword.get(opts, :listen_opts, [])
    task_supervisor = Keyword.get(opts, :task_supervisor, [])

    listen(server, port, task_supervisor, custom_opts)
  end

  defp listen(server, port, task_supervisor, custom_opts) do
    default_opts = [
      packet: :raw,
      active: false,
      reuseaddr: true
    ]

    listen_opts = Keyword.merge(default_opts, custom_opts)

    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary | listen_opts])

    Logger.debug("#{inspect(server)}: Accepting connections on port #{port}")

    accept_client(server, listen_socket, task_supervisor)
  end

  defp accept_client(server, listen_socket, task_supervisor) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)

    Task.Supervisor.async(task_supervisor, fn ->
      Logger.debug("#{inspect(server)}: Client Connected (#{inspect(client_socket)})")
      server.start(client_socket)
    end)

    accept_client(server, listen_socket, task_supervisor)
  end

  def child_spec(opts) do
    Supervisor.child_spec(
      {Task, fn -> __MODULE__.start_link(opts) end},
      id: Keyword.fetch!(opts, :server)
    )
  end
end
