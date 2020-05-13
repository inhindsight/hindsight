defmodule Plugins do
  @moduledoc """
  Utility module allowing Hindsight services to compile, load, and use
  custom protocol implementations. Custom impls must be placed in a `plugins/`
  directory at the running service's top level.

  The `plugins/` directory may contain any level of nested directories. All
  plugin files must end in `.ex` to be compiled.
  """
  use Properties, otp_app: :plugins
  require Logger

  defmodule PluginError do
    defexception [:message]
  end

  getter(:source_dir, default: "plugins")

  @spec load!() :: :ok
  def load! do
    load_plugins()
    |> case do
      {:ok, plugins} ->
        count = Enum.reject(plugins, &is_nil/1) |> Enum.count()
        Logger.info(fn -> "#{__MODULE__}: Loaded #{count} plugin files" end)
        :ok

      {:error, reason} ->
        raise PluginError.exception(message: inspect(reason))
    end
  end

  defp load_plugins do
    "#{source_dir()}/**/*.ex"
    |> Path.wildcard()
    |> Enum.map(&Path.expand/1)
    |> Ok.transform(&require_file/1)
  end

  defp require_file(path) do
    success = Code.require_file(path)
    Logger.debug(fn -> "#{__MODULE__}: Loaded #{path} plugin file" end)
    Ok.ok(success)
  catch
    _, reason ->
      Logger.error(fn -> "#{__MODULE__}: Failed to load plugin file #{path}" end)
      Ok.error(reason)
  end
end
