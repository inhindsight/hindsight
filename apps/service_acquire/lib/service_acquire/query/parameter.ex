defmodule Acquire.Query.Parameter do
  use Definition, schema: Acquire.Query.Parameter.V1

  defstruct [:value]

  def get_value(%__MODULE__{value: value}), do: value
  def get_value(_), do: nil
end

defmodule Acquire.Query.Parameter.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query.Parameter{
      value: spec(not_nil?())
    })
  end
end
