defmodule Dictionary.Type.Integer do
  use Definition, schema: Dictionary.Type.Integer.V1
  use Dictionary.JsonEncoder

  defstruct version: 1,
            name: nil,
            description: ""

  defimpl Dictionary.Type.Normalizer, for: __MODULE__ do
    def normalize(_field, value) when is_integer(value), do: Ok.ok(value)

    def normalize(_field, value) do
      case Integer.parse(value) do
        {parsed_value, _} -> Ok.ok(parsed_value)
        :error -> Ok.error(:invalid_integer)
      end
    end
  end
end

defmodule Dictionary.Type.Integer.V1 do
  use Definition.Schema

  def s do
    schema(%Dictionary.Type.Integer{
      version: version(1),
      name: required_string(),
      description: string()
    })
  end
end
