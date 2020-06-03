defmodule SecretStore.Environment do
  @moduledoc """
  Access secret values from your system environment.
  """

  @behaviour SecretStore

  @impl true
  def get(name, key, default) do
    assemble_name(name, key)
    |> String.upcase()
    |> String.replace("-", "_")
    |> System.get_env(default)
  end

  defp assemble_name(name, key) do
    [name, key, SecretStore.environment()]
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce("", fn
      "", acc -> acc
      val, "" -> val
      val, acc -> "#{acc}_#{val}"
    end)
  end
end
