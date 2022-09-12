defmodule Protohacker.Echo.Server do
  require Logger

  def start(socket), do: serve(socket)

  defp serve(socket) do
    with {:ok, data} <- :gen_tcp.recv(socket, 0),
         :ok <- :gen_tcp.send(socket, data) do
      serve(socket)
    else
      _error ->
        Logger.debug("#{inspect(__MODULE__)}: Client Closed (#{inspect(socket)})")
        :gen_tcp.close(socket)
    end
  end
end
