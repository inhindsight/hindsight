defmodule Load.Persist do
  use Definition, schema: Load.Persist.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          source: String.t(),
          destination: String.t(),
          config: map
        }

  @derive Jason.Encoder
  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            source: nil,
            destination: nil,
            config: %{}
end

defmodule Load.Persist.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Load.Persist{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      source: required_string(),
      destination: required_string(),
      config: spec(is_map())
    })
  end
end
