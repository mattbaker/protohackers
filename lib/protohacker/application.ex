defmodule Protohacker.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Protohacker.Echo.Supervisor, port: 3000},
      {Protohacker.Prime.Supervisor, port: 3001},
      {Protohacker.Bank.Supervisor, port: 3002}
    ]

    opts = [strategy: :one_for_one, name: Protohacker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
