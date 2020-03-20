defmodule Define.StepFieldView do
  use Definition, schema: Define.StepFieldView.V1
  alias Define.StepView

  @type t :: %__MODULE__{
    version: integer,
    key: string,
    type: string,
    value: string | boolean | map
  }

  @derive Jason.Encoder
  defstruct version: 1,
    key: nil,
    type: nil,
    value: nil
end

defmodule Define.StepFieldView.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.StepFieldView {
      version: version(1),
      key: string(),
      type: string(),
      # TODO: This better
      value: spec(is_binary() or is_boolean() or is_map())
      })
  end
end
