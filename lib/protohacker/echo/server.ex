defmodule Protohacker.Echo.Server do
  require Logger

  def start(client_socket), do: serve(client_socket)

  defp serve(client_socket) do
    with {:ok, data} <- :gen_tcp.recv(client_socket, 0),
         :ok <- :gen_tcp.send(client_socket, data) do
      serve(client_socket)
    else
      _error ->
        Logger.debug("#{inspect(__MODULE__)}: Client Closed (#{inspect(client_socket)})")
        :gen_tcp.close(client_socket)
    end
  end
end
