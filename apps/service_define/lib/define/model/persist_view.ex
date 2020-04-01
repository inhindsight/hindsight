defmodule Define.Model.PersistView do
  use Definition, schema: Define.Model.PersistView.V1

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

defmodule Define.Model.PersistView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.Model.PersistView{
      version: version(1),
      source: string(),
      destination: string()
    })
  end
end
