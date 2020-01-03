defmodule Dictionary.Type.List do
  use Definition, schema: Dictionary.Type.List.V1
  use Dictionary.JsonEncoder

  defstruct version: 1,
    name: nil,
    description: "",
    item_type: nil,
    fields: []

  defimpl Dictionary.Type.Decoder, for: __MODULE__ do
    def decode(_, values) do
      with {:ok, fields} <- decode_fields(Map.get(values, "fields", [])) do
        values
        |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
        |> Map.new()
        |> Map.put(:fields, fields)
        |> Dictionary.Type.List.new()
      end
    end

    defp decode_fields(fields) when is_list(fields) do
      Ok.transform(fields, &Dictionary.decode/1)
    end

    defp decode_fields(fields), do: Ok.ok(fields)
  end

end

defmodule Dictionary.Type.List.V1 do
  use Definition.Schema

  def s do
    schema(%Dictionary.Type.List{
          version: spec(fn v -> v == 1 end),
          name: spec(is_binary() and not_empty?()),
          description: spec(is_binary()),
          item_type: spec(is_binary() and not_empty?()),
          fields: spec(is_list())
    })
  end
end
