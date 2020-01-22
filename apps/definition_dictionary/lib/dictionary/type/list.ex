defmodule Dictionary.Type.List do
  use Definition, schema: Dictionary.Type.List.V1

  @type t :: %__MODULE__{
          version: integer,
          name: String.t(),
          description: String.t(),
          item_type: module,
          dictionary: Dictionary.t()
        }

  defstruct version: 1,
            name: nil,
            description: "",
            item_type: nil,
            dictionary: Dictionary.from_list([])

  @impl Definition
  def on_new(data) do
    with {:ok, item_type_module} <- get_item_type(data.item_type),
         {:ok, dictionary} <- decode_dictionary(data.dictionary) do
      data
      |> Map.put(:dictionary, dictionary)
      |> Map.put(:item_type, item_type_module)
      |> Ok.ok()
    end
  end

  defp get_item_type(item_type) do
    case is_binary(item_type) && item_type != "" do
      true -> Dictionary.Type.from_string(item_type)
      false -> {:ok, item_type}
    end
  end

  defp decode_dictionary(list) when is_list(list) do
    with {:ok, decoded_dictionary} <- Dictionary.decode(list) do
      Dictionary.from_list(decoded_dictionary)
      |> Ok.ok()
    end
  end

  defp decode_dictionary(other), do: Ok.ok(other)

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

  defimpl Brook.Serializer.Protocol, for: __MODULE__ do
    def serialize(data) do
      Map.put(data, :item_type, Dictionary.Type.to_string(data.item_type))
      |> Brook.Serializer.Protocol.Any.serialize()
    end
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
      dictionary: struct?(Dictionary.Impl)
    })
  end
end
