defmodule Profile.ViewState.Stats do
  @moduledoc """

  """
  use Management.ViewState,
    instance: Profile.Application.instance(),
    collection: "stats"
end
