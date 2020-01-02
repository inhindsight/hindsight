defmodule Dictionary.Type.Map do
  use Definition, schema: Dictionary.Type.Map.V1
  use Dictionary.JsonEncoder

  defstruct version: 1,
            name: nil,
            description: "",
            fields: []

  defimpl Dictionary.Type.Decoder, for: __MODULE__ do
    def decode(_, values) do
      with {:ok, fields} <- decode_fields(Map.get(values, "fields", [])) do
        values
        |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
        |> Map.new()
        |> Map.put(:fields, fields)
        |> Dictionary.Type.Map.new()
      end
    end

    defp decode_fields(fields) do
      Ok.transform(fields, &Dictionary.decode/1)
    end
  end
end

defmodule Dictionary.Type.Map.V1 do
  use Definition.Schema

  def s do
    schema(%Dictionary.Type.Map{
      version: spec(fn v -> v == 1 end),
      name: spec(is_binary() and not_empty?()),
      description: spec(is_binary()),
      fields: spec(is_list())
    })
  end
end
