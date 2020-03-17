defmodule Profile.Feed.Store do
  @instance Profile.Application.instance()
  @collection "profile_stats"

  import Definition, only: [identifier: 1, identifier: 2]

  @spec persist(Profile.Update.t()) :: :ok
  def persist(%Profile.Update{} = update) do
    Brook.ViewState.merge(@collection, identifier(update), %{"stats" => update.stats})
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
end
