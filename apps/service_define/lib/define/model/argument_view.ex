defmodule Define.Model.ArgumentView do
  use Definition, schema: Define.Model.ArgumentView.V1

  @type t :: %__MODULE__{
          version: integer,
          key: String.t(),
          type: String.t(),
          value: any()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            key: nil,
            type: nil,
            value: nil
end

defmodule Define.Model.ArgumentView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.Model.ArgumentView{
      version: version(1),
      key: string(),
      type: string()
    })
  end
end
