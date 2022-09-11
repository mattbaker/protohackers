defmodule Protohacker.Echo.ClientHandler do
  require Logger

  def start(client_socket), do: serve(client_socket)

  defp serve(client_socket) do
    with {:ok, data} <- :gen_tcp.recv(client_socket, 0),
         :ok <- :gen_tcp.send(client_socket, data) do
      serve(client_socket)
    else
      _ ->
        Logger.debug("Closing (#{inspect(client_socket)})")
        :gen_tcp.close(client_socket)
    end
  end
end
