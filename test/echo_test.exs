defmodule ProtohackerTest.EchoServerTest do
  use ExUnit.Case

  test "sends an echo" do
    socket = connect()
    on_exit(fn -> :gen_tcp.close(socket) end)

    :ok = :gen_tcp.send(socket, "hello world")
    {:ok, data} = :gen_tcp.recv(socket, 0)
    assert data == "hello world"
  end

  test "doesn't mangle binary data" do
    socket = connect()
    on_exit(fn -> :gen_tcp.close(socket) end)

    :ok = :gen_tcp.send(socket, <<1, 3, 3, 7>>)
    {:ok, data} = :gen_tcp.recv(socket, 0)
    assert data == <<1, 3, 3, 7>>
  end

  def connect() do
    {:ok, socket} =
      :gen_tcp.connect(:localhost, 3000, [{:active, false}, {:mode, :binary}, {:packet, :raw}])

    socket
  end
end
