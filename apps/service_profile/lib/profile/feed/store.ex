defmodule Profile.Feed.Store do
  @moduledoc """
  State management functions for events.
  """

  @instance Profile.Application.instance()
  @collection "feeds"

  import Definition, only: [identifier: 1, identifier: 2]

  @spec persist(Profile.Update.t()) :: :ok
  def persist(%Profile.Update{} = update) do
    Brook.ViewState.merge(@collection, identifier(update), %{"stats" => update.stats})
  end

  @spec persist(Extract.t()) :: :ok
  def persist(%Extract{} = extract) do
    Brook.ViewState.merge(@collection, identifier(extract), %{"extract" => extract})
  end

  @spec get_stats(dataset_id :: String.t(), subset_id :: String.t()) ::
          {:ok, map} | {:error, term}
  def get_stats(dataset_id, subset_id) do
    case Brook.get(@instance, @collection, identifier(dataset_id, subset_id)) do
      {:ok, nil} -> Ok.ok(%{})
      {:ok, map} -> Map.get(map, "stats", %{}) |> Ok.ok()
      error_result -> error_result
    end
  end

  @spec get_extract(dataset_id :: String.t(), subset_id :: String.t()) ::
          {:ok, Extract.t()} | {:error, term}
  def get_extract(dataset_id, subset_id) do
    case Brook.get(@instance, @collection, identifier(dataset_id, subset_id)) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, map} -> Map.get(map, "extract") |> Ok.ok()
      error_result -> error_result
    end
  end

  @spec get_all_extracts() :: [Extract.t()]
  def get_all_extracts() do
    case Brook.get_all_values(@instance, @collection) do
      {:ok, results} ->
        filtered_results =
          results
          |> Enum.map(&Map.get(&1, "extract"))
          |> Enum.filter(& &1)

        {:ok, filtered_results}

      {:error, _} ->
        {:error, "Failed to get values from Profile store"}
    end
  end
end
