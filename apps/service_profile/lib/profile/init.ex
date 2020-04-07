defmodule Profile.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Profile.Feed.Supervisor

  def on_start(state) do
    case Profile.Feed.Store.get_all_extracts() do
      {:ok, store} ->
        restore_state_from_store(store)
        {:ok, state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp restore_state_from_store(store) do
    store
    |> Enum.each(&Profile.Feed.Supervisor.start_child/1)
  end
end
