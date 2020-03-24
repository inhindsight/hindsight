defmodule Define.DictionarySerializationTest do
  use ExUnit.Case
  alias Define.{DictionarySerialization, DictionaryView, DictionaryFieldView}

  test "serializes non-hierarchical top level field" do
    dict = Dictionary.from_list([Dictionary.Type.String.new!(name: "letter")])

    expected = [
      %DictionaryView{
        struct_module_name: "Elixir.Dictionary.Type.String",
        fields: [
          %DictionaryFieldView{key: "description", type: "string", value: ""},
          %DictionaryFieldView{key: "name", type: "string", value: "letter"}
        ]
      }
    ]

    assert expected == DictionarySerialization.serialize(dict)
  end

  test "serializes lists" do
    dict =
      Dictionary.from_list([
        %Dictionary.Type.List{
          name: "pets",
          item_type: Dictionary.Type.String.new!(name: "pet_name")
        }
      ])

    expected = [
      %Define.DictionaryView{
        struct_module_name: "Elixir.Dictionary.Type.List",
        version: 1,
        fields: [
          %Define.DictionaryFieldView{key: "description", type: "string", value: "", version: 1},
          %Define.DictionaryFieldView{
            key: "item_type",
            version: 1,
            type: "dictionary",
            value: %Define.DictionaryView{
              struct_module_name: "Elixir.Dictionary.Type.String",
              fields: [
                %Define.DictionaryFieldView{
                  key: "description",
                  type: "string",
                  version: 1,
                  value: ""
                },
                %Define.DictionaryFieldView{
                  key: "name",
                  type: "string",
                  version: 1,
                  value: "pet_name"
                }
              ]
            }
          },
          %Define.DictionaryFieldView{key: "name", type: "string", value: "pets", version: 1}
        ]
      }
    ]

    assert expected == DictionarySerialization.serialize(dict)
  end

  test "serializes maps" do
    dict =
      Dictionary.from_list([
        Dictionary.Type.Map.new!(
          name: "person",
          dictionary: [
            Dictionary.Type.String.new!(name: "first_name"),
            Dictionary.Type.Integer.new!(name: "age")
          ]
        )
      ])

    expected = [
      %DictionaryView{
        struct_module_name: "Elixir.Dictionary.Type.Map",
        fields: [
          %DictionaryFieldView{key: "description", type: "string", value: ""},
          %DictionaryFieldView{
            key: "dictionary",
            type: "list",
            value: [
              %DictionaryView{
                struct_module_name: "Elixir.Dictionary.Type.String",
                fields: [
                  %DictionaryFieldView{key: "description", type: "string", value: ""},
                  %DictionaryFieldView{key: "name", type: "string", value: "first_name"}
                ]
              },
              %DictionaryView{
                struct_module_name: "Elixir.Dictionary.Type.Integer",
                fields: [
                  %DictionaryFieldView{key: "description", type: "string", value: ""},
                  %DictionaryFieldView{key: "name", type: "string", value: "age"}
                ]
              }
            ]
          },
          %DictionaryFieldView{key: "name", type: "string", value: "person"}
        ]
      }
    ]

    assert expected == DictionarySerialization.serialize(dict)
  end
end
