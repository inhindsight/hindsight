defmodule Gather.ViewState do
  @moduledoc false

  defmodule Extractions do
    @moduledoc """
    Management of extraction data in state.
    """
    use Management.ViewState,
      instance: Gather.Application.instance(),
      collection: "extractions"
  end

  defmodule Sources do
    @moduledoc """
    Management of source data in state.
    """
    use Management.ViewState,
      instance: Gather.Application.instance(),
      collection: "sources"
  end

  defmodule Destinations do
    @moduledoc """
    Management of destination data in state.
    """
    use Management.ViewState,
      instance: Gather.Application.instance(),
      collection: "destinations"
  end
end
