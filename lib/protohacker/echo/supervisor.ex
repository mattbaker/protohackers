defmodule Protohacker.Echo.Supervisor do
  use Supervisor

  def start_link(port: port) do
    Supervisor.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    children = [
      {Task.Supervisor, name: Protohacker.Echo.TaskSupervisor},
      {Protohacker.TcpListener,
       [
         server: Protohacker.Echo.Server,
         task_supervisor: Protohacker.Echo.TaskSupervisor,
         port: port
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
