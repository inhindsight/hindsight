defmodule Load.Broadcast do
  use Definition, schema: Load.Broadcast.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          source: String.t(),
          destination: String.t(),
          cache: integer,
          config: map
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            source: nil,
            destination: nil,
            cache: 0,
            config: %{}
end

defmodule Load.Broadcast.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Load.Broadcast{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      source: required_string(),
      destination: required_string(),
      cache: spec(is_integer()),
      config: spec(is_map())
    })
  end
end
