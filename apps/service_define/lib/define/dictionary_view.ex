defmodule Define.DictionaryView do
  use Dictionary, schema: Define.DictionaryView.V1
  alias Define.DictionaryField

  @type t :: %__MODULE__{
    version: integer,
    struct_module_name: string,
    fields: [DictionaryField.t()]
  }

  @derive Jason.Encoder
  defstruct version: 1,
    struct_module_name: nil,
    fields: []
end

defmodule Define.DictionaryView.V1 do
  use Dictionary.Schema

  @impl true
  def s do
    schema(%Define.DictionaryView {
      version: version(1),
      struct_module_name: string(),
      fields: list()
      })
  end
end
