defmodule Broadcast.Init do
  use Annotated.Retry

  use Initializer,
    name: __MODULE__,
    supervisor: Broadcast.Stream.Supervisor

  @retry with: constant_backoff(100) |> take(10)
  def on_start(state) do
    store = Broadcast.Stream.Store.get_all!()
    case(store) do
      {:error, _} -> {:error, "Broadcast failed to read state from store during startup"}
      _ ->
        store |> Enum.reject(&is_nil/1)
        |> Enum.reject(&Broadcast.Stream.Store.done?(&1))
        |> Enum.each(fn load ->
          Broadcast.Stream.Supervisor.start_child(load)
        end)
        {:ok, state}
    end
  end
end
