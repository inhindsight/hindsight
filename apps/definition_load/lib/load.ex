defmodule Load do
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
end

defmodule Load.V1 do
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
