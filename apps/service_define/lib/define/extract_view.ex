defmodule Define.ExtractView do
  use Definition, schema: Define.ExtractView.V1
  alias Define.{ModuleFunctionArgsView}

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

defmodule Define.ExtractView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.ExtractView{
      version: version(1),
      destination: string(),
      dictionary: list(),
      # TODO: Add is_list that takes a type
      steps: list()
    })
  end
end
