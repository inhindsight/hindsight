defmodule Define.Model.TransformView do
  @moduledoc """
  Representation of an Transform event.
  """
  use Definition, schema: Define.Model.TransformView.V1
  alias Define.Model.ModuleFunctionArgsView

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
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.Model.TransformView{
      version: version(1),
      dictionary: spec(is_list()),
      steps: spec(is_list())
    })
  end
end
