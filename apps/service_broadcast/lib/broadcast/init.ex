defmodule Broadcast.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Broadcast.Stream.Supervisor

  def on_start(state) do
    with {:ok, store} <- Broadcast.Stream.Store.get_all(),
      _ <- store |> Enum.reject(&is_nil/1)
        |> Enum.reject(&Broadcast.Stream.Store.done?(&1))
        |> Enum.each(fn load ->
          Broadcast.Stream.Supervisor.start_child(load) end)
      do
        {:ok, state}
      else
        {:error, _} -> {:error, "Failed reading initial state for Broadcast on startup"}
      end
  end
end
