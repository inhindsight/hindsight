defmodule Define.DictionarySerialization do
alias Define.{DictionaryView, DictionaryFieldView, TypespecAnalysis}

  def serialize(dictionary) do
      Enum.map(dictionary.ordered, fn value ->
        %DictionaryView{
          struct_module_name: to_string(value.__struct__),
          fields: TypespecAnalysis.get_types(value.__struct__) |> Map.delete(:version) |> Enum.map(fn {k, v} -> %DictionaryFieldView{key: k, type: v} end)
        }
      end)
  end
end
