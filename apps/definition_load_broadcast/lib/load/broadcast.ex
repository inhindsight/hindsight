defmodule Load.Broadcast do
  use Definition, schema: Load.Broadcast.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: uuid,
          name: String.t(),
          source: String.t(),
          destination: String.t(),
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            name: nil,
            source: nil,
            destination: nil

end

defmodule Load.Broadcast.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Load.Broadcast{
      version: version(1),
      id: id(),
      dataset_id: id(),
      name: required_string(),
      source: required_string(),
      destination: required_string(),
    })
  end
end
