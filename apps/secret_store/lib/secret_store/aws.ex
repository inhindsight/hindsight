defmodule SecretStore.Aws do
  @moduledoc """
  Access secret values from AWS SecretsManager.
  """

  @behaviour SecretStore

  @doc """
  Retrieve a secret string from AWS SecretsManager. Pass `nil`
  as key to retrieve an entire JSON document or if you're using
  a Plaintext secret.

  `default` argument is returned if the secret doesn't exist
  in SecretsManager (HTTP 400) or if the key doesn't exist in
  the JSON document.
  """
  @impl true
  def get(name, key, default \\ nil) do
    assemble_name(name)
    |> ExAws.SecretsManager.get_secret_value()
    |> ExAws.request()
    |> case do
      {:ok, result} -> decode(result, key, default)
      {:error, {:http_error, 400, _}} -> default
      {:error, reason} -> raise reason
    end
  end

  defp assemble_name(name) do
    [name, SecretStore.environment()]
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce("", fn
      "", acc -> acc
      val, "" -> val
      val, acc -> "#{acc}-#{val}"
    end)
  end

  defp decode(%{"SecretString" => data}, nil, default), do: data || default

  defp decode(%{"SecretString" => data}, key, default) do
    Jason.decode!(data)
    |> Map.get(key, default)
  end
end
