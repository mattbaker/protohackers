defmodule Protohacker.Mitm.Server do
  require Logger

  def start(client_sock, _opts) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        Protohacker.Mitm.DynamicSupervisor,
        {
          Protohacker.Mitm.User,
          [downstream_host: "localhost", downstream_port: 3003, client_socket: client_sock]
        }
      )

    :ok = :gen_tcp.controlling_process(client_sock, pid)
  end
end
