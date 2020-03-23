defmodule Dlq.Application do
  use Application

  def start(_type, _args) do
    children = [
      Dlq.Server
    ]

    opts = [strategy: :one_for_one, name: Dlq.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
