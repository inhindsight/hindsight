defmodule Broadcast.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Broadcast.Stream.Supervisor

  #Is moving the retry to initializer just moving the problem?
  # This feels like I still need to see if get_all returns an error or data
  def on_start(state) do
    case(Broadcast.Stream.Store.get_all()) do
      {:ok, results} ->
        results |> Enum.reject(&is_nil/1)
        |> Enum.reject(&Broadcast.Stream.Store.done?(&1))
        |> Enum.each(fn load ->
          Broadcast.Stream.Supervisor.start_child(load)
        end)
        {:ok, state}
      _ -> {:error, "Broadcast failed getting initial state on init"}
    end
  end
end
