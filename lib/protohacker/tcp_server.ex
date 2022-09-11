defmodule Protohacker.TcpServer do
  require Logger

  def start_link(opts) do
    client_handler = Keyword.fetch!(opts, :client_handler)
    port = Keyword.fetch!(opts, :port)
    custom_opts = Keyword.get(opts, :listen_opts, [])
    task_supervisor = Keyword.get(opts, :task_supervisor, [])

    listen(client_handler, port, task_supervisor, custom_opts)
  end

  defp listen(client_handler, port, task_supervisor, custom_opts) do
    default_opts = [
      packet: :raw,
      active: false,
      reuseaddr: true
    ]

    listen_opts = Keyword.merge(default_opts, custom_opts)

    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary | listen_opts] |> IO.inspect())

    Logger.debug("#{client_handler} accepting connections on port #{port}")

    accept_client(client_handler, listen_socket, task_supervisor)
  end

  defp accept_client(client_handler, listen_socket, task_supervisor) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)

    Task.Supervisor.async(task_supervisor, fn ->
      Logger.debug("New Client Connected (#{inspect(client_socket)})")
      client_handler.start(client_socket)
    end)

    accept_client(client_handler, listen_socket, task_supervisor)
  end

  def child_spec(opts) do
    Supervisor.child_spec(
      {Task, fn -> __MODULE__.start_link(opts) end},
      id: Keyword.fetch!(opts, :client_handler)
    )
  end
end
