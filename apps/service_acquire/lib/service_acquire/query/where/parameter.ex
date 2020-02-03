defmodule Acquire.Query.Where.Parameter do
  use Definition, schema: Acquire.Query.Where.Parameter.V1

  @type t :: %__MODULE__{value: term}

  defstruct [:value]

  @spec get_value(%__MODULE__{value: value}) :: value when value: term
  def get_value(%__MODULE__{value: value}), do: value
  def get_value(_), do: nil
end

defmodule Acquire.Query.Where.Parameter.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query.Where.Parameter{
      value: spec(not_nil?())
    })
  end
end
