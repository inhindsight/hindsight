defmodule Dictionary.Type.List do
  use Definition, schema: Dictionary.Type.List.V1

  defstruct version: 1,
            name: nil,
            description: "",
            item_type: nil,
            fields: []

  def on_new(data) do
    case data.item_type == "" || is_atom(data.item_type) do
      true -> data
      false -> Map.update!(data, :item_type, &String.to_existing_atom/1)
    end
    |> Ok.ok()
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    alias Dictionary.Type

    def encode(%{item_type: item_type} = value, opts) do
      value
      |> Map.put(:item_type, Type.to_string(item_type))
      |> Map.from_struct()
      |> Map.put(:type, Type.to_string(Dictionary.Type.List))
      |> Jason.Encode.map(opts)
    end
  end

  defimpl Dictionary.Type.Decoder, for: __MODULE__ do
    alias Dictionary.Type

    def decode(_, values) do
      with {:ok, item_type_module} <- get_item_type(Map.get(values, "item_type")),
           {:ok, fields} <- decode_fields(Map.get(values, "fields", [])) do
        values
        |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
        |> Map.new()
        |> Map.put(:fields, fields)
        |> Map.put(:item_type, item_type_module)
        |> Dictionary.Type.List.new()
      end
    end

    defp get_item_type(item_type) do
      case is_binary(item_type) && item_type != "" do
        true -> Type.from_string(item_type)
        false -> {:ok, item_type}
      end
    end

    defp decode_fields(fields) when is_list(fields) do
      Ok.transform(fields, &Dictionary.decode/1)
    end

    defp decode_fields(fields), do: Ok.ok(fields)
  end

  defimpl Dictionary.Type.Normalizer, for: __MODULE__ do
    alias Dictionary.Type.Normalizer

    def normalize(field, list) do
      sub_field = create_sub_field(field)

      Ok.transform(list, &Normalizer.normalize(sub_field, &1))
      |> Ok.map_if_error(fn reason -> {:invalid_list, reason} end)
    end

    defp create_sub_field(%{item_type: item_type} = field) do
      sub_field = struct(item_type)

      field
      |> Map.from_struct()
      |> Map.keys()
      |> Enum.filter(fn name -> Map.has_key?(sub_field, name) end)
      |> Enum.reduce(sub_field, fn name, sf ->
        Map.put(sf, name, Map.get(field, name))
      end)
    end
  end
end

defmodule Dictionary.Type.List.V1 do
  use Definition.Schema

  def s do
    schema(%Dictionary.Type.List{
      version: version(1),
      name: required_string(),
      description: string(),
      item_type: spec(is_atom() and not_nil?()),
      fields: spec(is_list())
    })
  end
end
