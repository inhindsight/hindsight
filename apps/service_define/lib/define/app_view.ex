defmodule Define.AppView do
  use Definition, schema: Define.AppView.V1
  alias Define.DataDefinition

  @type t :: %__MODULE__{
          version: integer,
          greeting: String.t(),
          data_definitions: [DataDefinition.t()]
        }

  @derive Jason.Encoder
  defstruct version: 1,
            greeting: "Hello",
            data_definitions: []
end

defmodule Define.AppView.V1 do
  use Definition.Schema
  alias Define.DataDefinition

  @impl true
  def s do
    schema(%Define.AppView{
      version: version(1),
      greeting: string(),
      data_definitions: of_struct(DataDefinition)
    })
  end
end