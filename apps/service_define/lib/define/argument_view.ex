defmodule Define.ArgumentView do
  use Definition, schema: Define.ArgumentView.V1

  @type t :: %__MODULE__{
          version: integer,
          key: String.t(),
          type: String.t(),
          value: String.t() | boolean | map
        }

  @derive Jason.Encoder
  defstruct version: 1,
            key: nil,
            type: nil,
            value: nil
end

defmodule Define.ArgumentView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.ArgumentView{
      version: version(1),
      key: string(),
      type: string(),
      # TODO: This better
      value: spec(is_binary() or is_boolean() or is_map())
    })
  end
end
