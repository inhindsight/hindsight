defmodule Define.DefinitionView do
  use Definition, schema: Define.DefinitionView.V1

  @type t :: %__MODULE__{
    version: integer,
    struct_module_name: string,
    fields: map
  }

  @derive Jason.Encoder
  defstruct version: 1,
    struct_module_name: nil,
    fields: %{}
end

defmodule Define.DefinitionView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.DefinitionView {
      version: version(1),
      struct_module_name: string(),
      fields: map()
      })
  end
end
