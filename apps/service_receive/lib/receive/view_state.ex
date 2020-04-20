defmodule Receive.ViewState do
  @moduledoc false

  defmodule Accepts do
    @moduledoc """
    Management of accept data in state.
    """
    use Management.ViewState,
      instance: Receive.Application.instance(),
      collection: "accepts"
  end

  defmodule Destinations do
    @moduledoc """
    Management of destination data in state.
    """
    use Management.ViewState,
      instance: Receive.Application.instance(),
      collection: "destinations"
  end
end
