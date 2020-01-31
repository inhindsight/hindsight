defmodule Acquire.Query.And do
  use Definition, schema: Acquire.Query.And.V1
  defstruct [:conditions]
end

defmodule Acquire.Query.And.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query.And{
      conditions: conditions()
    })
  end

  defp conditions do
    coll_of(spec(&condition?/1))
  end

  defp condition?(arg) do
    case Acquire.Queryable.impl_for(arg) do
      nil -> false
      _ -> true
    end
  end
end
