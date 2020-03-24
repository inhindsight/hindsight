defmodule Define.DefinitionSerializationTest do
  use ExUnit.Case
  alias Define.{DefinitionSerialization, ModuleFunctionArgsView, ArgumentView}

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
      %Define.ModuleFunctionArgsView{
        struct_module_name: "Elixir.Dictionary.Type.List",
        version: 1,
        args: [
          %Define.ArgumentView{key: "description", type: "string", value: "", version: 1},
          %Define.ArgumentView{
            key: "item_type",
            version: 1,
            type: "module",
            value: %Define.ModuleFunctionArgsView{
              struct_module_name: "Elixir.Dictionary.Type.String",
              args: [
                %Define.ArgumentView{
                  key: "description",
                  type: "string",
                  version: 1,
                  value: ""
                },
                %Define.ArgumentView{
                  key: "name",
                  type: "string",
                  version: 1,
                  value: "pet_name"
                }
              ]
            }
          },
          %Define.ArgumentView{key: "name", type: "string", value: "pets", version: 1}
        ]
      }
    ]

    assert expected == DefinitionSerialization.serialize(dict)
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
      %ModuleFunctionArgsView{
        struct_module_name: "Elixir.Dictionary.Type.Map",
        args: [
          %ArgumentView{key: "description", type: "string", value: ""},
          %ArgumentView{
            key: "dictionary",
            type: "module",
            value: [
              %ModuleFunctionArgsView{
                struct_module_name: "Elixir.Dictionary.Type.String",
                args: [
                  %ArgumentView{key: "description", type: "string", value: ""},
                  %ArgumentView{key: "name", type: "string", value: "first_name"}
                ]
              },
              %ModuleFunctionArgsView{
                struct_module_name: "Elixir.Dictionary.Type.Integer",
                args: [
                  %ArgumentView{key: "description", type: "string", value: ""},
                  %ArgumentView{key: "name", type: "string", value: "age"}
                ]
              }
            ]
          },
          %ArgumentView{key: "name", type: "string", value: "person"}
        ]
      }
    ]

    assert expected == DefinitionSerialization.serialize(dict)
  end

  test "serializes lists of maps" do
    dict =
      Dictionary.from_list([
        %Dictionary.Type.List{
          name: "people",
          item_type: Dictionary.Type.Map.new!(
            name: "person",
            dictionary: [
              Dictionary.Type.String.new!(name: "first_name"),
            ]
          )
        }
      ])

    expected = [
      %Define.ModuleFunctionArgsView{
        struct_module_name: "Elixir.Dictionary.Type.List",
        version: 1,
        args: [
          %Define.ArgumentView{key: "description", type: "string", value: "", version: 1},
          %Define.ArgumentView{
            key: "item_type",
            version: 1,
            type: "module",
            value: %Define.ModuleFunctionArgsView{
              struct_module_name: "Elixir.Dictionary.Type.Map",
              args: [
                %Define.ArgumentView{
                  key: "description",
                  type: "string",
                  version: 1,
                  value: ""
                },
                %Define.ArgumentView{
                  key: "dictionary",
                  type: "module",
                  version: 1,
                  value: [
                    %ModuleFunctionArgsView{
                      struct_module_name: "Elixir.Dictionary.Type.String",
                      args: [
                        %ArgumentView{key: "description", type: "string", value: ""},
                        %ArgumentView{key: "name", type: "string", value: "first_name"}
                      ]
                    },
                  ]
                },
                %Define.ArgumentView{
                  key: "name",
                  type: "string",
                  version: 1,
                  value: "person"
                },
              ]
            }
          },
          %Define.ArgumentView{key: "name", type: "string", value: "people", version: 1}
        ]
      }
    ]

    assert expected == DefinitionSerialization.serialize(dict)
  end

end
