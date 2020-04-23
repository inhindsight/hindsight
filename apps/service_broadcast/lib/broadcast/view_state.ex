defmodule Broadcast.ViewState do
  @moduledoc false

  defmodule Streams do
    @moduledoc """
    Management of stream metadata in state.
    """
    use Management.ViewState,
      instance: Broadcast.Application.instance(),
      collection: "streams"
  end

  defmodule Transformations do
    @moduledoc """
    Management of transformation metadata in state.
    """
    use Management.ViewState,
      instance: Broadcast.Application.instance(),
      collection: "transformations"
  end

  defmodule Sources do
    @moduledoc """
    Management of source metadata in state.
    """
    use Management.ViewState,
      instance: Broadcast.Application.instance(),
      collection: "sources"
  end

  defmodule Destinations do
    @moduledoc """
    Management of destination metadata in state.
    """
    use Management.ViewState,
      instance: Broadcast.Application.instance(),
      collection: "destinations"
  end
end
