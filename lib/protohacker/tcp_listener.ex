defmodule Protohacker.TcpListener do
  @moduledoc """
  A generic TCP listener that passes individual client connections
  off to the supplied "server" module.
  """
  require Logger

  def start_link(opts) do
    pid = spawn_link(__MODULE__, :init, [opts])
    {:ok, pid}
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :server)
    port = Keyword.fetch!(opts, :port)
    listen_opts = Keyword.get(opts, :listen_opts, [])
    server_opts = Keyword.get(opts, :server_opts, [])
    task_supervisor = Keyword.get(opts, :task_supervisor, [])

    listen(server, port, task_supervisor, listen_opts, server_opts)
  end

  defp listen(server, port, task_supervisor, listen_opts, server_opts) do
    default_opts = [
      packet: :raw,
      active: false,
      reuseaddr: true
    ]

    listen_opts = Keyword.merge(default_opts, listen_opts)

    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary | listen_opts])

    Logger.debug("#{inspect(server)}: Accepting connections on port #{port}")

    accept_client(server, listen_socket, task_supervisor, server_opts)
  end

  defp accept_client(server, listen_socket, task_supervisor, server_opts) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)

    if server_opts[:no_async] do
      start_server(server, client_socket, server_opts)
    else
      start_server_async(server, client_socket, server_opts)
    end

    accept_client(server, listen_socket, task_supervisor, server_opts)
  end

  defp start_server_async(server, client_socket, server_opts) do
    Task.Supervisor.async(Protohacker.TaskSupervisor, fn ->
      start_server(server, client_socket, server_opts)
    end)
  end

  defp start_server(server, client_socket, server_opts) do
    Logger.debug("#{inspect(server)}: Client Connected (#{inspect(client_socket)})")
    server.start(client_socket, server_opts)
  end

  def child_spec(opts) do
    %{
      id: {__MODULE__, opts[:server]},
      start: {__MODULE__, :start_link, [opts]}
    }
  end
end
