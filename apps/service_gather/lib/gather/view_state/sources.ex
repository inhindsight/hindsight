defmodule Gather.ViewState.Sources do
  @moduledoc """
  Management of source data in state.
  """
  use Management.ViewState,
    instance: Gather.Application.instance(),
    collection: "sources"
end
