defmodule Define.StepView do
  use Definition, schema: Define.StepView.V1

  @type t :: %__MODULE__{
    version: integer,
    struct_module_name: String.t(),
    fields: [StepFieldView.t()]
  }

  @derive Jason.Encoder
  defstruct version: 1,
    struct_module_name: nil,
    fields: []
end

defmodule Define.StepView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.StepView {
      version: version(1),
      struct_module_name: string(),
      fields: list()
      })
  end
end
