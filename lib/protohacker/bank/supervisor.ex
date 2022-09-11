defmodule Protohacker.Bank.Supervisor do
  use Supervisor

  def start_link(port: port) do
    Supervisor.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    children = [
      {Task.Supervisor, name: Protohacker.Bank.TaskSupervisor},
      {Protohacker.TcpServer,
       [
         client_handler: Protohacker.Bank.ClientHandler,
         task_supervisor: Protohacker.Bank.TaskSupervisor,
         port: port,
         listen_opts: [packet: :raw]
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
