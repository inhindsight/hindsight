defmodule Define.DictionarySerialization do
  alias Define.{DictionaryView, DictionaryFieldView, TypespecAnalysis}

  def serialize(dictionary) do
    Enum.map(dictionary.ordered, fn field ->
      %DictionaryView{
        struct_module_name: to_string(field.__struct__),
        fields:
          TypespecAnalysis.get_types(field.__struct__)
          |> Map.delete(:version)
          |> Enum.map(&(call_to_dictionary_field_view(&1, field)))
      }
    end)
  end

  defp call_to_dictionary_field_view({field_key, _field_value_type} = field_key_to_type, field) do
    field_value = Map.get(field, String.to_atom(field_key))
    to_dictionary_field_view(field_key_to_type, field_value)
  end

  defp to_dictionary_field_view({"item_type", _}, field) do
    type = %DictionaryView{
      struct_module_name: to_string(field.__struct__),
      fields:
        TypespecAnalysis.get_types(field.__struct__)
        |> Map.delete(:version)
        |> Enum.map(&(to_dictionary_field_view(&1, field)))
    }

    %DictionaryFieldView{key: "item_type", type: type}
  end

  defp to_dictionary_field_view({field_key, field_value_type}, _), do: %DictionaryFieldView{key: field_key, type: field_value_type}
end
