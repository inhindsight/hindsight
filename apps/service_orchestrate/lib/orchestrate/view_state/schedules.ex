defmodule Orchestrate.ViewState.Schedules do
  @moduledoc """
  State management functions for events.
  """
  use Management.ViewState,
    instance: Orchestrate.Application.instance(),
    collection: "schedules"
end
