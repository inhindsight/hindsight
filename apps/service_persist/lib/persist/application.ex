defmodule Persist.Application do
  @moduledoc false

  use Application

  def instance(), do: :persist_instance

  def start(_type, _args) do
    children =
      [
        Persist.Load.Registry,
        Persist.Load.Supervisor,
        brook()
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Persist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp brook() do
    case Application.get_env(:service_persist, :brook) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end
