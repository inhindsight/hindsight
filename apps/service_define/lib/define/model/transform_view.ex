defmodule Define.Model.TransformView do
  use Definition, schema: Define.Model.TransformView.V1
  alias Define.{ModuleFunctionArgsView}

  @type t :: %__MODULE__{
          version: integer,
          dictionary: [ModuleFunctionArgsView.t()],
          steps: [ModuleFunctionArgsView.t()]
        }

  @derive Jason.Encoder
  defstruct version: 1,
            dictionary: [],
            steps: []
end

defmodule Define.Model.TransformView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.Model.TransformView{
      version: version(1),
      dictionary: list(),
      steps: list()
    })
  end
end
