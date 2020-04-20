defmodule Define.DefinitionSerializationTest do
  use ExUnit.Case
  alias Define.Model.{ModuleFunctionArgsView, ArgumentView}
  alias Define.DefinitionSerialization

  test "serializes non-hierarchical top level field" do
    dict = Dictionary.from_list([Dictionary.Type.String.new!(name: "letter")])

    expected = [
      %ModuleFunctionArgsView{
        struct_module_name: "Elixir.Dictionary.Type.String",
        args: [
          %ArgumentView{key: "description", type: "string", value: ""},
          %ArgumentView{key: "name", type: "string", value: "letter"}
        ]
      }
    ]

    assert expected == DefinitionSerialization.serialize(dict)
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
      %ModuleFunctionArgsView{
        struct_module_name: "Elixir.Dictionary.Type.List",
        version: 1,
        args: [
          %ArgumentView{key: "description", type: "string", value: "", version: 1},
          %ArgumentView{
            key: "item_type",
            version: 1,
            type: "module",
            value: %ModuleFunctionArgsView{
              struct_module_name: "Elixir.Dictionary.Type.String",
              args: [
                %ArgumentView{
                  key: "description",
                  type: "string",
                  version: 1,
                  value: ""
                },
                %ArgumentView{
                  key: "name",
                  type: "string",
                  version: 1,
                  value: "pet_name"
                }
              ]
            }
          },
          %ArgumentView{key: "name", type: "string", value: "pets", version: 1}
        ]
      }
    ]

    assert expected == DefinitionSerialization.serialize(dict)
  end

  test "serializes modules" do
    source = Dictionary.Type.String.new!(name: "letter")

    expected = %ModuleFunctionArgsView{
      struct_module_name: "Elixir.Dictionary.Type.String",
      args: [
        %ArgumentView{key: "description", type: "string", value: ""},
        %ArgumentView{key: "name", type: "string", value: "letter"}
      ]
    }

    assert expected == DefinitionSerialization.serialize(source)
  end

  test "serializes lists of maps" do
    dict =
      Dictionary.from_list([
        %Dictionary.Type.List{
          name: "people",
          item_type:
            Dictionary.Type.Map.new!(
              name: "person",
              dictionary: [
                Dictionary.Type.String.new!(name: "first_name")
              ]
            )
        }
      ])

    expected = [
      %ModuleFunctionArgsView{
        struct_module_name: "Elixir.Dictionary.Type.List",
        version: 1,
        args: [
          %ArgumentView{key: "description", type: "string", value: "", version: 1},
          %ArgumentView{
            key: "item_type",
            version: 1,
            type: "module",
            value: %ModuleFunctionArgsView{
              struct_module_name: "Elixir.Dictionary.Type.Map",
              args: [
                %ArgumentView{
                  key: "description",
                  type: "string",
                  version: 1,
                  value: ""
                },
                %ArgumentView{
                  key: "dictionary",
                  type: {"list", "module"},
                  version: 1,
                  value: [
                    %ModuleFunctionArgsView{
                      struct_module_name: "Elixir.Dictionary.Type.String",
                      args: [
                        %ArgumentView{key: "description", type: "string", value: ""},
                        %ArgumentView{key: "name", type: "string", value: "first_name"}
                      ]
                    }
                  ]
                },
                %ArgumentView{
                  key: "name",
                  type: "string",
                  version: 1,
                  value: "person"
                }
              ]
            }
          },
          %ArgumentView{key: "name", type: "string", value: "people", version: 1}
        ]
      }
    ]

    assert expected == DefinitionSerialization.serialize(dict)
  end

  test "serializes steps" do
    steps = [
      Extract.Http.Get.new!(
        url: "http://localhost/file.csv",
        headers: %{"content-length" => "5"}
      )
    ]

    expected = [
      %ModuleFunctionArgsView{
        struct_module_name: "Elixir.Extract.Http.Get",
        args: [
          %ArgumentView{
            key: "headers",
            type: "map",
            value: %{"content-length" => "5"}
          },
          %ArgumentView{
            key: "url",
            type: "string",
            value: "http://localhost/file.csv"
          }
        ]
      }
    ]

    assert expected == DefinitionSerialization.serialize(steps)
  end
end
