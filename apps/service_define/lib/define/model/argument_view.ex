defmodule Define.Model.ArgumentView do
  @moduledoc """
  Represents an argument name, value, and type that will be used to create a struct.
  """
  use Definition, schema: Define.Model.ArgumentView.V1

  @type t :: %__MODULE__{
          version: integer,
          key: String.t(),
          type: String.t() | list(String.t()),
          value: any()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            key: "",
            type: "",
            value: nil
end

defmodule Define.Model.ArgumentView.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.Model.ArgumentView{
      version: version(1),
      key: string(),
      type: spec(is_binary() or is_list())
    })
  end
end
