defmodule Dictionary.Type.Float do
  use Definition, schema: Dictionary.Type.Float.V1
  use Dictionary.JsonEncoder

  defstruct version: 1,
            name: nil,
            description: ""

  defimpl Dictionary.Type.Normalizer, for: __MODULE__ do
    def normalize(_field, value) when value in [nil, ""], do: Ok.ok(nil)

    def normalize(_field, value) when is_integer(value) or is_float(value) do
      Ok.ok(value / 1)
    end

    def normalize(_field, value) do
      case Float.parse(value) do
        {parsed_value, _} -> Ok.ok(parsed_value)
        :error -> Ok.error(:invalid_float)
      end
    end
  end
end

defmodule Dictionary.Type.Float.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Dictionary.Type.Float{
      version: version(1),
      name: lowercase_string(),
      description: string()
    })
  end
end
