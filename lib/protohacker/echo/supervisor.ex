defmodule Protohacker.Echo.Supervisor do
  use Supervisor

  def start_link(port: port) do
    Supervisor.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    children = [
      {Task.Supervisor, name: Protohacker.Echo.TaskSupervisor},
      {Protohacker.TcpServer,
       [
         client_handler: Protohacker.Echo.ClientHandler,
         task_supervisor: Protohacker.Echo.TaskSupervisor,
         port: port
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
