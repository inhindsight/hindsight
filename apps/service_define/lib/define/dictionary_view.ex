defmodule Define.DictionaryView do
  use Definition, schema: Define.DictionaryView.V1
  alias Define.DictionaryField

  @type t :: %__MODULE__{
    version: integer,
    struct_module_name: String.t(),
    fields: [DictionaryField.t()]
  }

  @derive Jason.Encoder
  defstruct version: 1,
    struct_module_name: nil,
    fields: []
end

defmodule Define.DictionaryView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.DictionaryView {
      version: version(1),
      struct_module_name: string(),
      fields: list()
      })
  end
end
