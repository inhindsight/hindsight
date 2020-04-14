defmodule Gather.Init do
  @moduledoc """
  Implementation of `Initializer` behaviour to reconnect to
  pre-existing event state.
  """
  use Initializer,
    name: __MODULE__,
    supervisor: Gather.Extraction.Supervisor

  alias Gather.Extraction

  def on_start(state) do
    Extraction.Store.get_all!()
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&Extraction.Store.done?(&1))
    |> Enum.each(fn extract ->
      Extraction.Supervisor.start_child(extract)
    end)

    {:ok, state}
  end
end
