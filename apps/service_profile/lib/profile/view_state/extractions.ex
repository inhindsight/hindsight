defmodule Profile.ViewState.Extractions do
  @moduledoc """
  State management functions for events.
  """
  use Management.ViewState,
    instance: Profile.Application.instance(),
    collection: "feeds"
end
