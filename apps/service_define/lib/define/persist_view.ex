defmodule Define.PersistView do
  use Definition, schema: Define.PersistView.V1

  @type t :: %__MODULE__{
          version: integer,
          source: String.t(),
          destination: String.t()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            source: nil,
            destination: nil
end

defmodule Define.PersistView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.PersistView{
      version: version(1),
      source: string(),
      destination: string()
    })
  end
end
