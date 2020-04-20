defmodule Gather.ViewState.Extractions do
  @moduledoc """
  Management of extraction data in state.
  """
  use Management.ViewState,
    instance: Gather.Application.instance(),
    collection: "extractions"
end
