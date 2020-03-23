defmodule Define.DictionaryFieldView do
  use Definition, schema: Define.DictionaryFieldView.V1
  alias Define.DictionaryView

  @type t :: %__MODULE__{
          version: integer,
          key: String.t(),
          type: String.t() | DictionaryView.t() | DictionaryFieldView.t()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            key: nil,
            type: nil
end

defmodule Define.DictionaryFieldView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.DictionaryFieldView{
      version: version(1),
      key: string(),
      # TODO: Find a way to call out the struct specifically (like of_struct())
      type: spec(is_binary() or is_map())
    })
  end
end
