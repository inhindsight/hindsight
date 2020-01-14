defmodule Load.Persist do
  use Definition, schema: Load.Persist.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: uuid,
          name: String.t(),
          source: String.t(),
          destination: String.t(),
          schema: list()
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            name: nil,
            source: nil,
            destination: nil,
            schema: []
end

defmodule Load.Persist.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Load.Persist{
      version: version(1),
      id: id(),
      dataset_id: id(),
      name: required_string(),
      source: required_string(),
      destination: required_string(),
      schema: spec(is_list())
    })
  end
end
