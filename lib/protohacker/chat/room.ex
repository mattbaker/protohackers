defmodule Protohacker.Chat.Room do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %{users: %{}}}
  end

  def register(name, socket) do
    GenServer.call(__MODULE__, {:register, name, socket})
  end

  def broadcast(name, message) do
    GenServer.call(__MODULE__, {:broadcast, name, message})
  end

  def goodbye(name) do
    GenServer.call(__MODULE__, {:goodbye, name})
  end

  def handle_call({:register, name}, _, %{users: users} = state)
      when is_map_key(users, name) do
    {:reply, {:error, :already_registered}, state}
  end

  def handle_call({:register, name, socket}, _, %{users: users} = state) do
    Logger.debug("New user #{name}")

    announce_user(name, users)
    send_welcome(socket, users)

    {:reply, :ok, %{state | users: Map.put(users, name, socket)}}
  end

  def handle_call({:broadcast, name, message}, _, %{users: users} = state) do
    Logger.debug("New message #{name}: #{message}")

    broadcast(name, message, users)

    {:reply, :ok, state}
  end

  def handle_call({:goodbye, name}, _, %{users: users} = state) do
    Logger.debug("Departed user #{name}")

    users = Map.drop(users, [name])
    goodbye(name, users)

    {:reply, :ok, %{state | users: users}}
  end

  defp announce_user(name, users) do
    Enum.each(users, fn {_, socket} ->
      :gen_tcp.send(socket, "* #{name} has joined\n")
    end)
  end

  defp send_welcome(socket, users) do
    :gen_tcp.send(socket, "* In room: #{Map.keys(users) |> Enum.join(",")}\n")
  end

  defp broadcast(name, message, users) do
    Map.drop(users, [name])
    |> Enum.each(fn {_, socket} ->
      :gen_tcp.send(socket, "[#{name}] #{message}\n")
    end)
  end

  defp goodbye(name, users) do
    Enum.each(users, fn {_, socket} ->
      :gen_tcp.send(socket, "* #{name} disconnected\n")
    end)
  end
end
