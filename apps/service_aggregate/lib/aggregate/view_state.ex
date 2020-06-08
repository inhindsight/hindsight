defmodule Aggregate.ViewState do
  @moduledoc false

  defmodule Extractions do
    @moduledoc """
    State management functions for events.
    """
    use Management.ViewState,
      instance: Aggregate.Application.instance(),
      collection: "feeds"
  end

  defmodule Stats do
    @moduledoc """
    State management functions for profiling statistics.
    """
    use Management.ViewState,
      instance: Aggregate.Application.instance(),
      collection: "stats"
  end
end
