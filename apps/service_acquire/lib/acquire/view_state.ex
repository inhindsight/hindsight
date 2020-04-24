defmodule Acquire.ViewState do
  @moduledoc false

  defmodule Fields do
    @moduledoc """
    Management of field metadata in state.
    """
    use Management.ViewState,
      instance: Acquire.Application.instance(),
      collection: "fields"
  end

  defmodule Destinations do
    @moduledoc """
    Management of destination metadata in state.
    """
    use Management.ViewState,
      instance: Acquire.Application.instance(),
      collection: "destinations"
  end
end
