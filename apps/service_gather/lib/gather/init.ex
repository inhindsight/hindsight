defmodule Gather.Init do
  use Retry
  use Initializer,
    name: __MODULE__,
    supervisor: Gather.Extraction.Supervisor

  alias Gather.Extraction

  def on_start(state) do
    retry with: constant_backoff(100) do
      Extraction.Store.get_all!()
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&Extraction.Store.done?(&1))
      |> Enum.each(fn extract ->
        Extraction.Supervisor.start_child(extract)
      end)
    after
      _ ->
        {:ok, state}
    else
      _ -> {:stop, "Could not read state from store", state}
    end
  end
end
