defmodule Define.Model.ExtractView do
  use Definition, schema: Define.Model.ExtractView.V1
  alias Define.Model.{ModuleFunctionArgsView}

  @type t :: %__MODULE__{
          version: integer,
          destination: String.t(),
          dictionary: [ModuleFunctionArgsView.t()],
          steps: [ModuleFunctionArgsView.t()]
        }

  @derive Jason.Encoder
  defstruct version: 1,
            destination: nil,
            dictionary: [],
            steps: []
end

defmodule Define.Model.ExtractView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.Model.ExtractView{
      version: version(1),
      destination: string(),
      dictionary: list(),
      steps: list()
    })
  end
end
