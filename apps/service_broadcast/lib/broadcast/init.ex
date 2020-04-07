defmodule Broadcast.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Broadcast.Stream.Supervisor

  def on_start(state) do
    case Broadcast.Stream.Store.get_all() do
      {:ok, store} ->
        restore_state_from_store(store)
        {:ok, state}

      {:error, reason} -> {:error, reason}
    end
  end

  def restore_state_from_store(store) do
    store
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&Broadcast.Stream.Store.done?(&1))
    |> Enum.each(fn load -> Broadcast.Stream.Supervisor.start_child(load) end)
  end
end
