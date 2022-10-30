defmodule Protohacker.Mitm.User do
  use GenServer, restart: :temporary
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    client_s = opts[:client_socket]

    {:ok, downstream_s} =
      :gen_tcp.connect(
        opts[:downstream_host] |> String.to_charlist(),
        opts[:downstream_port],
        [:binary, packet: :line, buffer: 1024 * 1000, active: true]
      )

    :ok = :inet.setopts(client_s, active: true)

    {:ok, {client_s, downstream_s}}
  end

  def handle_info({:tcp, source_s, message}, {source_s, dest_s} = sockets) do
    handle_forward(message, dest_s, sockets)
  end

  def handle_info({:tcp, source_s, message}, {dest_s, source_s} = sockets) do
    handle_forward(message, dest_s, sockets)
  end

  def handle_info({:tcp_closed, _}, sockets) do
    {:stop, :shutdown, sockets}
  end

  def terminate(reason, {client_s, downstream_s}) do
    :gen_tcp.close(client_s)
    :gen_tcp.close(downstream_s)
    reason
  end

  defp handle_forward(message, dest_s, sockets) do
    :gen_tcp.send(dest_s, rewrite(message))
    |> case do
      :ok -> {:noreply, sockets}
      _ -> {:stop, :shutdown, sockets}
    end
  end

  @bogus_coin_pattern ~r/^7[a-zA-Z0-9]{25,34}$/
  @tony_addr "7YWHMfk9JZe0LM0g1ZauHuiSxhI"
  defp rewrite(msg) do
    String.split(msg)
    |> Enum.map(fn part ->
      if part =~ @bogus_coin_pattern, do: @tony_addr, else: part
    end)
    |> Enum.join(" ")
    |> String.trim()
    |> Kernel.<>("\n")
  end
end
