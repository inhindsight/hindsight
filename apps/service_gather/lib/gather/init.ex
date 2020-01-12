defmodule Gather.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Gather.Extraction.Supervisor

  alias Gather.Extraction

  def on_start(state) do
    Extraction.Store.get_all!()
    |> Enum.each(fn extract ->
      Extraction.Supervisor.start_child({Extraction, extract: extract})
    end)

    {:ok, state}
  end
end
