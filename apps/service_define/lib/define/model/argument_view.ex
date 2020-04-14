defmodule Define.Model.ArgumentView do
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
