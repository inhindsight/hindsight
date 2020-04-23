defmodule Persist.ViewState do
  @moduledoc false

  defmodule Loads do
    @moduledoc """
    Management of load metadata in state.
    """
    use Management.ViewState,
      instance: Persist.Application.instance(),
      collection: "loads"
  end

  defmodule Sources do
    @moduledoc """
    Management of source metadata in state.
    """
    use Management.ViewState,
      instance: Persist.Application.instance(),
      collection: "sources"
  end

  defmodule Destinations do
    @moduledoc """
    Management of destination metadata in state.
    """
    use Management.ViewState,
      instance: Persist.Application.instance(),
      collection: "destinations"
  end

  defmodule Transformations do
    @moduledoc """
    Management of transformation metadata in state.
    """
    use Management.ViewState,
      instance: Persist.Application.instance(),
      collection: "transformations"
  end

  defmodule Compactions do
    @moduledoc """
    Management of compaction metadata in state.
    """
    use Management.ViewState,
      instance: Persist.Application.instance(),
      collection: "compactions"
  end
end
