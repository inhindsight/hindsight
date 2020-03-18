defmodule Profile.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_profile

  def instance(), do: :profile_instance

  def start(_type, _args) do
    children =
      [
        Profile.Feed.Registry,
        Profile.Feed.Supervisor,
        brook(),
        # init()
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Profile.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init() do
    case get_config_value(:init?, default: true) do
      true -> Profile.Init
      false -> []
    end
  end

  defp brook() do
    case get_config_value(:brook, required: true) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end
