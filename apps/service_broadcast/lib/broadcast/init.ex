defmodule Broadcast.Init do
  use Retry
  use Initializer,
    name: __MODULE__,
    supervisor: Broadcast.Stream.Supervisor

  def on_start(state) do
    retry with: constant_backoff(100) do
      Broadcast.Stream.Store.get_all!()
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&Broadcast.Stream.Store.done?(&1))
      |> Enum.each(fn load ->
        Broadcast.Stream.Supervisor.start_child(load)
      end)
    after
      _ ->
        {:ok, state}
    else
      _ -> {:stop, "Could not read state from store", state}
    end
  end
end
