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
    with {:ok, view_state} <- Gather.ViewState.Extractions.get_all() do
      Map.values(view_state)
      |> Enum.each(&Extraction.Supervisor.start_child/1)

      Ok.ok(state)
    end
  end
end
