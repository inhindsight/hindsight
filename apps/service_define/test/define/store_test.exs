defmodule Define.StoreTest do
  use ExUnit.Case

  alias Define.{
    DataDefinitionView,
    ExtractView,
    DictionaryView,
    DictionaryFieldView,
    StepView,
    StepFieldView
  }

  @instance Define.Application.instance()

  test "put_in_better works" do
    initial = %{a: %{b: %{c: "A"}}}
    expected = %{a: %{b: %{c: "Z"}}}

    assert Define.Store.put_in_better(initial, [:a, :b, :c], "Z") == expected
  end

  describe "update_definition/1" do
    setup do
      on_exit(fn -> Define.Store.delete_all_definitions() end)
      :ok
    end

    test "persists a new extract" do
      id = "adataset"

      Brook.Test.with_event(@instance, fn ->
        event =
          Extract.new!(
            id: "extract-1",
            dataset_id: id,
            subset_id: "default",
            destination: "success",
            dictionary: [
              Dictionary.Type.String.new!(name: "letter")
            ],
            steps: [
              Extract.Http.Get.new!(
                url: "http://localhost/file.csv",
                headers: %{"content-length" => "5"}
              )
            ]
          )

        Define.Store.update_definition(event)
      end)

      persisted = Define.Store.get(id)

      expected = %DataDefinitionView{
        version: 1,
        dataset_id: id,
        extract: %ExtractView{
          destination: "success",
          steps: [
            %StepView{
              struct_module_name: "Elixir.Extract.Http.Get",
              fields: [
                %StepFieldView{
                  key: "headers",
                  type: "map",
                  value: %{"content-length" => "5"}
                },
                %StepFieldView{
                  key: "url",
                  type: "string",
                  value: "http://localhost/file.csv"
                }
              ]
            }
          ]
        },
        dictionary: [
          %DictionaryView{
            struct_module_name: "Elixir.Dictionary.Type.String",
            fields: [
              %DictionaryFieldView{
                key: "name",
                type: "letter"
              }
            ]
          }
        ],
        subset_id: "default"
      }

      assert expected == persisted
                %StepFieldView{
                  key: "url",
                  type: "string",
                  value: "http://localhost/file.csv"
                }
              ]
            }
          ]
        },
        dictionary: [
          %DictionaryView{
            struct_module_name: "Elixir.Dictionary.Type.String",
            fields: [
              %DictionaryFieldView{
                key: "name",
                type: "letter"
              }
            ]
          }
        ],
        subset_id: "default"
      }

      assert expected == persisted
                %StepFieldView{
                  key: "url",
                  type: "string",
                  value: "http://localhost/file.csv"
                }
              ]
            }
          ]
        },
        dictionary: [
          %DictionaryView{
            struct_module_name: "Elixir.Dictionary.Type.String",
            fields: [
              %DictionaryFieldView{
                key: "name",
                type: "letter"
              }
            ]
          }
        ],
        subset_id: "default"
      }

      assert expected == persisted
                %StepFieldView{
                  key: "url",
                  type: "string",
                  value: "http://localhost/file.csv"
                }
              ]
            }
          ]
        },
        dictionary: [
          %DictionaryView{
            struct_module_name: "Elixir.Dictionary.Type.String",
            fields: [
              %DictionaryFieldView{
                key: "name",
                type: "letter"
              }
            ]
          }
        ],
        subset_id: "default"
      }

      assert expected == persisted
                %StepFieldView{
                  key: "url",
                  type: "string",
                  value: "http://localhost/file.csv"
                }
              ]
            }
          ]
        },
        dictionary: [
          %DictionaryView{
            struct_module_name: "Elixir.Dictionary.Type.String",
            fields: [
              %DictionaryFieldView{
                key: "name",
                type: "letter"
              }
            ]
          }
        ],
        subset_id: "default"
      }

      assert expected == persisted
                %StepFieldView{
                  key: "url",
                  type: "string",
                  value: "http://localhost/file.csv"
                }
              ]
            }
          ]
        },
        dictionary: [
          %DictionaryView{
            struct_module_name: "Elixir.Dictionary.Type.String",
            fields: [
              %DictionaryFieldView{
                key: "name",
                type: "letter"
              }
            ]
          }
        ],
        subset_id: "default"
      }

      assert expected == persisted
                %StepFieldView{
                  key: "url",
                  type: "string",
                  value: "http://localhost/file.csv"
                }
              ]
            }
          ]
        },
        dictionary: [
          %DictionaryView{
            struct_module_name: "Elixir.Dictionary.Type.String",
            fields: [
              %DictionaryFieldView{
                key: "name",
                type: "letter"
              }
            ]
          }
        ],
        subset_id: "default"
      }

      assert expected == persisted
                %StepFieldView{
                  key: "url",
                  type: "string",
                  value: "http://localhost/file.csv"
                }
              ]
            }
          ]
        },
        dictionary: [
          %DictionaryView{
            struct_module_name: "Elixir.Dictionary.Type.String",
            fields: [
              %DictionaryFieldView{
                key: "name",
                type: "letter"
              }
            ]
          }
        ],
        subset_id: "default"
      }

      assert expected == persisted
                %StepFieldView{
                  key: "url",
                  type: "string",
                  value: "http://localhost/file.csv"
                }
              ]
            }
          ]
        },
        dictionary: [
          %DictionaryView{
            struct_module_name: "Elixir.Dictionary.Type.String",
            fields: [
              %DictionaryFieldView{
                key: "name",
                type: "letter"
              }
            ]
          }
        ],
        subset_id: "default"
      }

      assert expected == persisted
    end

    #   Brook.Test.with_event(@instance, fn ->
    #     event =
    #       Transform.new!(
    #         id: "transform-1",
    #         dataset_id: id,
    #         subset_id: "default",
    #         dictionary: [],
    #         steps: []
    #       )

    #     Define.Store.update_definition(event)
    #   end)

    #   persisted = Define.Store.get(id)

    #   expected = %Define.DataDefinitionView{
    #     dataset_id: id,
    #     subset_id: "default",
    #     dictionary: %Dictionary.Impl{by_name: %{}, by_type: %{}, ordered: [], size: 0},
    #     transform_steps: [],
    #     version: 1
    #   }

    #   assert ^expected = persisted
    # end

    # test "persists a new persist" do
    #   id = "bdataset"

    #   Brook.Test.with_event(@instance, fn ->
    #     event =
    #       Load.Persist.new!(
    #         id: "persist-1",
    #         dataset_id: id,
    #         subset_id: "default",
    #         source: "akafkatopic",
    #         destination: "storage__json"
    #       )

    #     Define.Store.update_definition(event)
    #   end)

    #   persisted = Define.Store.get(id)

    #   expected = %Define.DataDefinitionView{
    #     dataset_id: id,
    #     persist_source: "akafkatopic",
    #     persist_destination: "storage__json",
    #     subset_id: "default",
    #     version: 1
    #   }

    #   assert ^expected = persisted
    # end

    # test "persists updated fields when two events are posted" do
    #   id = "cDataset"

    #   Brook.Test.with_event(@instance, fn ->
    #     event =
    #       Extract.new!(
    #         id: "extract-1",
    #         dataset_id: id,
    #         subset_id: "default",
    #         destination: "success",
    #         dictionary: [],
    #         steps: []
    #       )

    #     Define.Store.update_definition(event)
    #   end)

    #   Brook.Test.with_event(@instance, fn ->
    #     event =
    #       Load.Persist.new!(
    #         id: "persist-1",
    #         dataset_id: id,
    #         subset_id: "default",
    #         source: "akafkatopic",
    #         destination: "storage__json"
    #       )

    #     Define.Store.update_definition(event)
    #   end)

    #   persisted = Define.Store.get(id)

    #   expected = %Define.DataDefinitionView{
    #     dataset_id: id,
    #     extract_destination: "success",
    #     extract_steps: [],
    #     dictionary: %Dictionary.Impl{by_name: %{}, by_type: %{}, ordered: [], size: 0},
    #     persist_source: "akafkatopic",
    #     persist_destination: "storage__json",
    #     subset_id: "default",
    #     version: 1
    #   }

    #   assert ^expected = persisted
    # end
  end
end
