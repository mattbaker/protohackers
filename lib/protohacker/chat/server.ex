defmodule Protohacker.Chat.Server do
  require Logger

  def start(socket, _opts) do
    :gen_tcp.send(socket, "Welcome to budgetchat! What shall I call you?\n")
    read_username(socket)
  end

  defp read_username(socket) do
    with {:ok, name} <- read(socket),
         true <- Regex.match?(~r/^[a-zA-Z0-9]{1,16}$/, name),
         :ok <- Protohacker.Chat.Room.register(name, socket) do
      serve(socket, name)
    else
      _ -> :gen_tcp.close(socket)
    end
  end

  defp serve(socket, name) do
    with {:ok, message} <- read(socket) do
      Protohacker.Chat.Room.broadcast(name, message)
      serve(socket, name)
    else
      _error ->
        Protohacker.Chat.Room.goodbye(name)
        Logger.debug("#{inspect(__MODULE__)}: Client Closed (#{inspect(socket)})")
        :gen_tcp.close(socket)
    end
  end

  defp read(socket) do
    with {:ok, message} <- :gen_tcp.recv(socket, 0),
         message <- String.trim(message),
         true <- String.valid?(message) do
      {:ok, message}
    else
      _ -> :error
    end
  end
end
