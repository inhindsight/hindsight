defmodule Dictionary.Field do
  use Definition, schema: Dictionary.Field.V1

  defstruct version: nil,
            name: nil,
            type: nil,
            description: "",
            fields: []

  defmodule InvalidChildFieldError do
    defexception [:message, :index, :errors]
  end

  def new(%{fields: fields} = input) when is_list(fields) and fields != [] do
    results =
      fields
      |> Enum.with_index()
      |> Enum.map(fn {field, index} -> {new(field), index} end)

    case Ok.all?(results, fn {field, _} -> field end) do
      true ->
        validated_fields = Enum.map(results, fn {{:ok, field}, _index} -> field end)

        Map.put(input, :fields, validated_fields)
        |> super()
      false -> create_exceptions(results)
    end
  end

  def new(input) do
    super(input)
  end

  defp create_exceptions(results) do
    results
    |> Enum.filter(fn {field, _index} -> match?({:error, _}, field) end)
    |> Enum.map(fn {{:error, reason}, index} ->
      InvalidChildFieldError.exception(message: "Invalid child field", index: index, errors: reason)
    end)
    |> Ok.error()
  end
end
