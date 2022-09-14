defmodule ProtohackerTest.VariableMessageSizeTest do
  use ExUnit.Case
  import Protohacker.BinaryShorthand

  defmodule TestServer do
    def start(socket, opts), do: serve(socket, opts)

    defp serve(socket, opts) do
      test_pid = Keyword.get(opts, :test_pid)

      with {:ok, data} <- :gen_tcp.recv(socket, 0) do
        {string, rest} = extract_string(data)
        send(test_pid, {:recv, :string, string})
        send(test_pid, {:recv, :remainder, rest})
        serve(socket, opts)
      else
        _error ->
          :gen_tcp.close(socket)
      end
    end

    defp extract_string(data, string \\ "")
    defp extract_string(<<0, rest::binary>>, string), do: {string, rest}
    defp extract_string(<<>>, string), do: {string, <<>>}

    defp extract_string(<<char, rest::binary>>, string),
      do: extract_string(rest, string <> <<char>>)
  end

  @port 9000
  setup do
    start_supervised!({
      Protohacker.TcpListener,
      server: TestServer, port: @port, listen_opts: [packet: 4], server_opts: [test_pid: self()]
    })

    :ok
  end

  test "greets the world" do
    {:ok, socket} =
      :gen_tcp.connect(:localhost, @port, [{:active, false}, {:mode, :binary}, {:packet, :raw}])

    on_exit(fn ->
      :ok = :gen_tcp.close(socket)
    end)

    payload = <<13::uint32(), "hello world", 0, 255::uint8()>>

    :ok = :gen_tcp.send(socket, payload)

    assert_receive({:recv, :string, "hello world"})
    assert_receive({:recv, :remainder, <<255::uint8()>>})
    # case :gen_tcp.recv(socket, 0) do
    #   {:ok, data} ->
    #     IO.inspect(data)
    #     :ok = :gen_tcp.close(socket)

    #   {:error, :closed} ->
    #     IO.puts("Server closed socket.")
    # end
  end
end
