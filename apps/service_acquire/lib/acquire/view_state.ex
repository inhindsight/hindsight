defmodule Acquire.ViewState do
  @moduledoc false

  defmodule Fields do
    @moduledoc """
    Management of field metadata in state.
    """
    use Management.ViewState,
      instance: Acquire.Application.instance(),
      collection: "fields"

    def persist(key, object) do
      super(key, %{key => object})
    end

    def get(key) do
      super(key)
      |> Ok.map(fn
        nil -> nil
        map -> Map.get(map, key)
      end)
    end
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
