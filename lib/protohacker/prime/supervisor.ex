defmodule Protohacker.Prime.Supervisor do
  use Supervisor

  def start_link(port: port) do
    Supervisor.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    children = [
      {Task.Supervisor, name: Protohacker.Prime.TaskSupervisor},
      {Protohacker.TcpListener,
       [
         server: Protohacker.Prime.Server,
         task_supervisor: Protohacker.Prime.TaskSupervisor,
         port: port,
         listen_opts: [packet: :line, buffer: 1024 * 1000]
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
