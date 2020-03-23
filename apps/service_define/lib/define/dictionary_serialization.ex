defmodule Define.DictionarySerialization do
  alias Define.{DictionaryView, DictionaryFieldView, TypespecAnalysis}

  def serialize(dictionary) do
    Enum.map(dictionary.ordered, fn value ->
      %DictionaryView{
        struct_module_name: to_string(value.__struct__),
        fields:
          TypespecAnalysis.get_types(value.__struct__)
          |> Map.delete(:version)
          |> Enum.map(&to_dictionary_field_view/1)
      }
    end)
  end

  defp to_dictionary_field_view({"item_type", value}) do
    value |> IO.inspect(label: "lib/define/dictionary_serialization.ex:17") 

    type = %DictionaryView{
      struct_module_name: to_string(value.__struct__),
      fields:
        TypespecAnalysis.get_types(value.__struct__)
        |> Map.delete(:version)
        |> Enum.map(&to_dictionary_field_view/1)
    }

    %DictionaryFieldView{key: "item_type", type: type}
  end

  defp to_dictionary_field_view({key, value}), do: %DictionaryFieldView{key: key, type: value}
end
