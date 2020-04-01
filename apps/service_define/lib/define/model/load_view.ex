defmodule Define.Model.LoadView do
  use Definition, schema: Define.Model.LoadView.V1

  @type t :: %__MODULE__{
          version: integer,
          source: String.t(),
          destination: String.t()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            source: "",
            destination: ""
end

defmodule Define.Model.LoadView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.Model.LoadView{
      version: version(1),
      source: string(),
      destination: string()
    })
  end
end
