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
        [:binary, packet: :line, buffer: 1024 * 1000, active: false]
      )

    # :inet.setopts(client_s, active: true)
    :inet.setopts(client_s, active: :once)
    :inet.setopts(downstream_s, active: :once)

    {:ok, {client_s, downstream_s}}
  end

  def handle_info({:tcp, client_s, message}, {client_s, downstream_s} = sockets) do
    Logger.debug("Client: '#{message}' from #{inspect(client_s)}")
    reply = handle_forward(message, downstream_s, sockets)
    :inet.setopts(client_s, active: :once)
    reply
  end

  def handle_info({:tcp, downstream_s, message}, {client_s, downstream_s} = sockets) do
    Logger.debug("Server: '#{message}' from #{inspect(downstream_s)}")
    reply = handle_forward(message, client_s, sockets)
    :inet.setopts(downstream_s, active: :once)
    reply
  end

  def handle_info({:tcp_closed, socket}, sockets) do
    Logger.debug("#{inspect(socket)} hung up")
    close_all(sockets)
    {:stop, :shutdown, sockets}
  end

  def terminate(reason, {client_s, downstream_s}) do
    Logger.debug("Closing #{inspect({client_s, downstream_s})}: #{inspect(reason)}")
    # :gen_tcp.close(downstream_s)
    # :gen_tcp.close(client_s)
    reason
  end

  defp close_all({s1, s2}) do
    :gen_tcp.close(s1)
    :gen_tcp.close(s2)
  end

  defp handle_forward(message, dest_s, sockets) do
    forward(message, dest_s)
    |> case do
      :ok ->
        {:noreply, sockets}

      e ->
        close_all(sockets)
        Logger.debug("Terminating #{inspect(e)}, #{inspect(sockets)}")
        {:stop, :shutdown, sockets}
    end
  end

  defp forward(message, dest) do
    new_message = rewrite(message)
    Logger.debug("Sending '#{new_message}' to #{inspect(dest)}")
    :gen_tcp.send(dest, new_message)
  end

  @tony_addr "7YWHMfk9JZe0LM0g1ZauHuiSxhI"
  defp rewrite(msg) do
    String.replace(msg, ~r/( |^)?(7[a-zA-Z0-9]{25,34})( |$)/, "\\g{1}#{@tony_addr}\\g{3}")
  end
end
