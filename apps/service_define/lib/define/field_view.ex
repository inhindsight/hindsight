defmodule Define.FieldView do
  use Definition, schema: Define.FieldView.V1
  alias Define.DefinitionView

  @type t :: %__MODULE__{
    version: integer,
    key: string,
    type: string | DefinitionView.t()
  }

  @derive Jason.Encoder
  defstruct version: 1,
    key: nil,
    type: nil
end

defmodule Define.FieldView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.FieldView {
      version: version(1),
      key: string(),
      type: spec(atom() or of_struct(DefinitionView))
      })
  end
end
