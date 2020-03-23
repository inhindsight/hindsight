defmodule Define.DictionarySerializationTest do
  use ExUnit.Case
  alias Define.{DictionarySerialization, DictionaryView, DictionaryFieldView}

  test "Serializes non-hierarchical top level field" do
    dict = Dictionary.from_list([Dictionary.Type.String.new!(name: "letter")])

    expected =
      [
        %DictionaryView{
          struct_module_name: "Elixir.Dictionary.Type.String",
          fields: [
            %DictionaryFieldView{key: "description", type: "string"},
            %DictionaryFieldView{key: "name", type: "string"}
          ]
        }
    ]

    assert expected == DictionarySerialization.serialize(dict)
  end
end
