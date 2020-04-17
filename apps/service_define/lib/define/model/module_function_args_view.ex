defmodule Define.Model.ModuleFunctionArgsView do
  @moduledoc """
  Representation of a definition struct and arguments that will be used to invoke the `new` function.
  """
  use Definition, schema: Define.Model.ModuleFunctionArgsView.V1
  alias Define.Model.ArgumentView

  @type t :: %__MODULE__{
          version: integer,
          struct_module_name: String.t(),
          args: [ArgumentView.t()]
        }

  @derive Jason.Encoder
  defstruct version: 1,
            struct_module_name: "",
            args: []
end

defmodule Define.Model.ModuleFunctionArgsView.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.Model.ModuleFunctionArgsView{
      version: version(1),
      struct_module_name: string(),
      args: list()
    })
  end
end
