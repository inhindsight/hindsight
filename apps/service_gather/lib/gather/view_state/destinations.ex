defmodule Gather.ViewState.Destinations do
  @moduledoc """
  Management of destination data in state.
  """
  use Management.ViewState,
    instance: Gather.Application.instance(),
    collection: "destinations"
end
