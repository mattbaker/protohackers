defmodule Protohacker.Mitm.User do
  use GenServer
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

    :inet.setopts(client_s, active: true)

    # read first couple messages in passive mode to ensure we don't
    # try to rewrite the "registration" exchange, then switch to passive?

    {:ok, {client_s, downstream_s}}
  end

  def handle_info({:tcp, client_s, message}, {client_s, downstream_s} = sockets) do
    handle_forward(message, downstream_s, sockets)
  end

  def handle_info({:tcp, downstream_s, message}, {client_s, downstream_s} = sockets) do
    handle_forward(message, client_s, sockets)
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
    forward(message, dest_s)
    |> case do
      :ok ->
        {:noreply, sockets}

      _ ->
        {:stop, :shutdown, sockets}
    end
  end

  defp forward(message, dest) do
    :gen_tcp.send(dest, rewrite(message))
  end

  @tony_addr "7YWHMfk9JZe0LM0g1ZauHuiSxhI"
  @body_match ~r/^(\[.*\] )?(.*)$/
  @boguscoin_matcher ~r/(^| b)^7[a-zA-Z0-9]{25,34}($| b)/
  defp rewrite(message) do
    String.replace(message, ~r/( |^)(7[a-zA-Z0-9]{25,34})( |$)/, "\\1#{@tony_addr}\\3")
    # IO.inspect(message, label: "Before")

    # with [_, _, body] <- Regex.run(@body_match, message),
    #      parts <- String.split(body, " ") |> IO.inspect() do
    #   Enum.map(parts, fn part ->
    #     String.replace(part, @boguscoin_matcher, @tony_addr)
    #   end)
    #   |> Enum.join(" ")
    #   |> Kernel.<>("\n")
    # else
    #   _ -> message
    # end
    # |> IO.inspect(label: "after")
  end
end
