defmodule Define.PersistView do
  use Definition, schema: Define.DataDefinition.V1

  @type t :: %__MODULE__{
    version: integer,
    source: String.t(),
    destination: String.t()
  }

  @derive Jason.Encoder
  defstruct version: 1,
    source: nil,
    destination: nil
end

defmodule Define.DataDefinition.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.DataDefinition {
      version: version(1),
      source: string(),
      destination: string()
    })
  end
end
