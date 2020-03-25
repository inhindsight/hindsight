defmodule StoreTest do
  use ExUnit.Case

  alias Define.{
    Store,
    DataDefinitionView,
    ExtractView,
    ModuleFunctionArgsView,
    ArgumentView,
    PersistView,
    TransformView
  }

  @instance Define.Application.instance()

  describe "update_definition/1" do
    setup do
      on_exit(fn -> Store.delete_all_definitions() end)
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

        Store.update_definition(event)
      end)

      persisted = Store.get(id)

      expected = %DataDefinitionView{
        version: 1,
        dataset_id: id,
        extract: %ExtractView{
          destination: "success",
          dictionary: [
            %ModuleFunctionArgsView{
              struct_module_name: "Elixir.Dictionary.Type.String",
              args: [
                %ArgumentView{
                  key: "description",
                  type: "string",
                  value: ""
                },
                %ArgumentView{
                  key: "name",
                  type: "string",
                  value: "letter"
                }
              ]
            }
          ],
          steps: [
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
        },
        subset_id: "default"
      }

      assert expected == persisted
    end

    test "persists a new persist" do
      id = "bdataset"

      Brook.Test.with_event(@instance, fn ->
        event =
          Load.Persist.new!(
            id: "persist-1",
            dataset_id: id,
            subset_id: "default",
            source: "akafkatopic",
            destination: "storage__json"
          )

        Store.update_definition(event)
      end)

      persisted = Store.get(id)

      expected =
        PersistView.new!(
          source: "akafkatopic",
          destination: "storage__json",
          version: 1
        )

      assert id == persisted.dataset_id
      assert "default" == persisted.subset_id
      assert expected == persisted.persist
    end

    test "persists a new transform" do
      id = "tdataset"

      Brook.Test.with_event(@instance, fn ->
        event =
          Transform.new!(
            id: "transform-1",
            dataset_id: id,
            subset_id: "default",
            dictionary: [
              Dictionary.Type.String.new!(name: "letter")
            ],
            steps: [
              Transform.Wkt.Point.new!(
                longitude: "long",
                latitude: "lat",
                to: "point"
              )
            ]
          )

        Store.update_definition(event)
      end)

      persisted = Store.get(id)

      expected = %DataDefinitionView{
        version: 1,
        dataset_id: id,
        transform: %TransformView{
          dictionary: [
            %ModuleFunctionArgsView{
              struct_module_name: "Elixir.Dictionary.Type.String",
              args: [
                %ArgumentView{
                  key: "description",
                  type: "string",
                  value: ""
                },
                %ArgumentView{
                  key: "name",
                  type: "string",
                  value: "letter"
                }
              ]
            }
          ],
          steps: [
            %ModuleFunctionArgsView{
              struct_module_name: "Elixir.Transform.Wkt.Point",
              args: [
                %ArgumentView{
                  key: "latitude",
                  type: "string",
                  value: "lat"
                },
                %ArgumentView{
                  key: "longitude",
                  type: "string",
                  value: "long"
                },
                %ArgumentView{
                  key: "to",
                  type: "string",
                  value: "point"
                }
              ]
            }
          ]
        },
        subset_id: "default"
      }

      assert expected == persisted
    end

    test "persists updated args when two events are posted" do
      id = "cDataset"

      Brook.Test.with_event(@instance, fn ->
        event =
          Extract.new!(
            id: "extract-1",
            dataset_id: id,
            subset_id: "default",
            destination: "success",
            dictionary: [Dictionary.Type.String.new!(name: "person")],
            steps: []
          )

        Store.update_definition(event)
      end)

      Brook.Test.with_event(@instance, fn ->
        event =
          Load.Persist.new!(
            id: "persist-1",
            dataset_id: id,
            subset_id: "default",
            source: "akafkatopic",
            destination: "storage__json"
          )

        Store.update_definition(event)
      end)

      persisted = Store.get(id)

      expected = %DataDefinitionView{
        dataset_id: id,
        subset_id: "default",
        extract: %ExtractView{
          destination: "success",
          dictionary: [
            %ModuleFunctionArgsView{
              struct_module_name: "Elixir.Dictionary.Type.String",
              args: [
                %ArgumentView{
                  key: "description",
                  type: "string",
                  value: ""
                },
                %ArgumentView{
                  key: "name",
                  type: "string",
                  value: "person"
                }
              ]
            }
          ],
          steps: []
        },
        persist: %PersistView{
          source: "akafkatopic",
          destination: "storage__json"
        },
        version: 1
      }

      assert expected == persisted
    end
  end

  describe "get/1" do
    test "returns DataDefinitionView" do
      id = "my-id"

      Brook.Test.with_event(@instance, fn ->
        event =
          Extract.new!(
            id: "extract-1",
            dataset_id: id,
            subset_id: "default",
            destination: "success",
            dictionary: [Dictionary.Type.String.new!(name: "person")],
            steps: []
          )

        Store.update_definition(event)
      end)

      expected = %DataDefinitionView{
        dataset_id: id,
        subset_id: "default",
        extract: %ExtractView{
          destination: "success",
          dictionary: [
            %ModuleFunctionArgsView{
              struct_module_name: "Elixir.Dictionary.Type.String",
              args: [
                %ArgumentView{
                  key: "description",
                  type: "string",
                  value: ""
                },
                %ArgumentView{
                  key: "name",
                  type: "string",
                  value: "person"
                }
              ]
            }
          ],
          steps: []
        },
        version: 1
      }

      assert expected == Store.get(id)
    end

    test "when id does not exist returns nil" do
      assert nil == Store.get("non-existant-id")
    end
  end

  describe "get_all/0" do
    test "returns all DataDefinitionViews" do
      Enum.each(1..3, fn index ->
        Brook.Test.with_event(@instance, fn ->
          event = %Extract{
              id: "extract-#{index}",
              dataset_id: "id-#{index}"
        }

          Store.update_definition(event)
        end)
      end)

      assert 3 == length(Store.get_all())
    end
  end
end
