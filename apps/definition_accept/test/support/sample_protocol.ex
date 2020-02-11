defmodule Accept.SampleProtocol do
  use Definition, schema: Accept.SampleProtocol.V1
  defstruct port: nil, key: nil, batch: nil
end

defmodule Accept.SampleProtocol.V1 do
  use Definition.Schema
  @impl true
  def s do
    schema(%Accept.SampleProtocol{
          port: spec(is_integer()),
          key: required_string(),
          batch: spec(is_integer())
})
  end
end
