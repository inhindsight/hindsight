defmodule Define.StepView do
  use Step, schema: Define.StepView.V1
  alias Define.StepFieldView

  @type t :: %__MODULE__{
    version: integer,
    struct_module_name: string,
    fields: [StepFieldView.t()]
  }

  @derive Jason.Encoder
  defstruct version: 1,
    struct_module_name: nil,
    fields: []
end

defmodule Define.StepView.V1 do
  use Step.Schema

  @impl true
  def s do
    schema(%Define.StepView {
      version: version(1),
      struct_module_name: string(),
      fields: list()
      })
  end
end
