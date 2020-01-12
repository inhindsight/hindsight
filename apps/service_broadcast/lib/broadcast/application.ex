defmodule Broadcast.Application do
  @moduledoc false

  use Application

  @config Application.get_env(:service_broadcast, __MODULE__, [])

  def instance(), do: :broadcast_instance

  def start(_type, _args) do
    children = [
      Broadcast.Stream.Registry,
      Broadcast.Stream.Supervisor,
      BroadcastWeb.Endpoint,
      brook(),
      init()
    ] |> List.flatten()

    opts = [strategy: :one_for_one, name: Broadcast.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init() do
    case Keyword.get(@config, :init?, true) do
      true -> Broadcast.Init
      false -> []
    end
  end

  defp brook() do
    case Application.get_env(:service_broadcast, :brook) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end

  def config_change(changed, _new, removed) do
    BroadcastWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
