defmodule Define.DictionaryFieldView do
  use Definition, schema: Define.DictionaryFieldView.V1
  alias Define.DictionaryView

  @type t :: %__MODULE__{
          version: integer,
          key: String.t(),
          type: String.t(),
          value: DictionaryView.t() | String.t() | boolean | map
        }

  @derive Jason.Encoder
  defstruct version: 1,
            key: nil,
            type: nil,
            value: nil
end

defmodule Define.DictionaryFieldView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.DictionaryFieldView{
      version: version(1),
      key: string(),
      # TODO call out DictionaryView
      value: spec(is_binary() or is_boolean() or is_map())
    })
  end
end
