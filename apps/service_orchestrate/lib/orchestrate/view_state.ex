defmodule Orchestrate.ViewState do
  @moduledoc false

  defmodule Schedules do
    @moduledoc """
    State management functions for events.
    """
    use Management.ViewState,
      instance: Orchestrate.Application.instance(),
      collection: "schedules"
  end
end
