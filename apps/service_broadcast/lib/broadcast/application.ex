defmodule Broadcast.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Broadcast.Stream.Supervisor,
      BroadcastWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Broadcast.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    BroadcastWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
