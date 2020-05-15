defmodule Load do
  @moduledoc """
  Defines a load event, reading data from a `Source.t()` and writing it
  to a `Destination.t()`.

  ## Configuration

  * `id` - Optional. Event instance UUID.
  * `dataset_id` - Required. Dataset identifier.
  * `subset_id` - Required. Dataset's subset identifier.
  * `source` - Required. `Source` impl to read data from.
  * `destination` - Required. `Destination` impl to write data to.
  """
  use Definition, schema: Load.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          source: Source.t(),
          destination: Destination.t()
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            source: nil,
            destination: nil

  def on_new(lo = %{id: nil}) do
    Map.put(lo, :id, UUID.uuid4())
    |> Ok.ok()
  end

  def on_new(lo) do
    Ok.ok(lo)
  end
end

defmodule Load.V1 do
  @moduledoc false
  use Definition.Schema

  def s do
    schema(%Load{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      source: impl_of(Source),
      destination: impl_of(Destination)
    })
  end
end
