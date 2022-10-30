defmodule Protohacker.Mitm.Server do
  require Logger

  def start(client_sock, opts) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        Protohacker.Mitm.DynamicSupervisor,
        {
          Protohacker.Mitm.User,
          Keyword.merge(opts, client_socket: client_sock)
        }
      )

    :ok = :gen_tcp.controlling_process(client_sock, pid)
  end
end
