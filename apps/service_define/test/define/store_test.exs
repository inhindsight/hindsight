defmodule StoreTest do
  use ExUnit.Case
  import AssertAsync
  import Definition, only: [identifier: 1]

  @moduletag capture_log: true

  alias Define.Model.{
    DataDefinitionView,
    ExtractView,
    ModuleFunctionArgsView,
    ArgumentView,
    LoadView,
    TransformView
  }

  alias Define.Event.Store

  @instance Define.Application.instance()

  setup do
    on_exit(fn -> Store.delete_all_definitions() end)
    :ok
  end

  describe "update_definition/1" do
    test "persists a new extract" do
      event =
        Extract.new!(
          id: "extract-1",
          dataset_id: "adataset",
          subset_id: "default",
          source: Source.Fake.new!(),
          destination: Destination.Fake.new!(),
          dictionary: [
            Dictionary.Type.String.new!(name: "letter")
          ],
          decoder: Decoder.Json.new!([])
        )

      Brook.Test.with_event(@instance, fn -> Store.update_definition(event) end)

      expected = %DataDefinitionView{
        version: 1,
        dataset_id: "adataset",
        extract: %ExtractView{
          destination: %ModuleFunctionArgsView{
            struct_module_name: "Elixir.Destination.Fake"
          },
          source: %ModuleFunctionArgsView{
            struct_module_name: "Elixir.Source.Fake"
          },
          decoder: %ModuleFunctionArgsView{
            struct_module_name: "Elixir.Decoder.Json"
          },
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
          ]
        },
        subset_id: "default"
      }

      assert_async do
        assert expected == Store.get(identifier(event))
      end
    end

    test "does not persist invalid extracts" do
      event = %Extract{
        id: "extract-1",
        dataset_id: "invalid_dataset",
        subset_id: "123",
        dictionary: [
          Dictionary.Type.String.new!(name: "letter")
        ],
        source: "invalid_value",
        destination: Destination.Fake.new!(),
        decoder: Decoder.Json.new!([])
      }

      Brook.Test.with_event(@instance, fn -> Store.update_definition(event) end)

      assert_async do
        assert nil == Store.get(identifier(event))
      end
    end

    test "persists a new persist" do
      event =
        Load.new!(
          id: "load-1",
          dataset_id: "bdataset",
          subset_id: "default",
          source: Source.Fake.new!(),
          destination: Destination.Fake.new!()
        )

      Brook.Test.with_event(@instance, fn -> Store.update_definition(event) end)

      expected = %LoadView{
        destination: %ModuleFunctionArgsView{struct_module_name: "Elixir.Destination.Fake"},
        source: %ModuleFunctionArgsView{struct_module_name: "Elixir.Source.Fake"},
        version: 1
      }

      assert_async do
        persisted = Store.get(identifier(event))

        assert event.dataset_id == persisted.dataset_id
        assert "default" == persisted.subset_id
        assert expected == persisted.load
      end
    end

    test "persists a new transform" do
      event =
        Transform.new!(
          id: "transform-1",
          dataset_id: "tdataset",
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

      Brook.Test.with_event(@instance, fn ->
        Store.update_definition(event)
      end)

      expected = %DataDefinitionView{
        version: 1,
        dataset_id: "tdataset",
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

      assert_async do
        assert expected == Store.get(identifier(event))
      end
    end

    test "persists updated args when two events are posted" do
      eventA =
        Extract.new!(
          id: "extract-1",
          dataset_id: "cDataset",
          subset_id: "default",
          source: Source.Fake.new!(),
          destination: Destination.Fake.new!(),
          decoder: Decoder.Json.new!([]),
          dictionary: [Dictionary.Type.String.new!(name: "person")]
        )

      Brook.Test.with_event(@instance, fn ->
        Store.update_definition(eventA)
      end)

      eventB =
        Load.new!(
          id: "load-1",
          dataset_id: "cDataset",
          subset_id: "default",
          source: Source.Fake.new!(),
          destination: Destination.Fake.new!()
        )

      Brook.Test.with_event(@instance, fn ->
        Store.update_definition(eventB)
      end)

      expected = %DataDefinitionView{
        dataset_id: "cDataset",
        subset_id: "default",
        extract: %ExtractView{
          destination: %ModuleFunctionArgsView{
            struct_module_name: "Elixir.Destination.Fake"
          },
          source: %ModuleFunctionArgsView{
            struct_module_name: "Elixir.Source.Fake"
          },
          decoder: %ModuleFunctionArgsView{
            struct_module_name: "Elixir.Decoder.Json"
          },
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
          ]
        },
        load: %LoadView{
          destination: %ModuleFunctionArgsView{struct_module_name: "Elixir.Destination.Fake"},
          source: %ModuleFunctionArgsView{struct_module_name: "Elixir.Source.Fake"},
          version: 1
        },
        version: 1
      }

      assert_async do
        assert expected == Store.get(identifier(eventB))
      end
    end
  end

  describe "get/1" do
    test "returns DataDefinitionView" do
      event =
        Extract.new!(
          id: "extract-1",
          dataset_id: "my-id",
          subset_id: "default",
          source: Source.Fake.new!(),
          destination: Destination.Fake.new!(),
          decoder: Decoder.Json.new!([]),
          dictionary: [Dictionary.Type.String.new!(name: "person")]
        )

      Brook.Test.with_event(@instance, fn ->
        Store.update_definition(event)
      end)

      expected = %DataDefinitionView{
        dataset_id: "my-id",
        subset_id: "default",
        extract: %ExtractView{
          destination: %Define.Model.ModuleFunctionArgsView{
            args: [],
            struct_module_name: "Elixir.Destination.Fake",
            version: 1
          },
          source: %Define.Model.ModuleFunctionArgsView{
            args: '',
            struct_module_name: "Elixir.Source.Fake",
            version: 1
          },
          decoder: %Define.Model.ModuleFunctionArgsView{
            args: '',
            struct_module_name: "Elixir.Decoder.Json",
            version: 1
          },
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
          ]
        },
        version: 1
      }

      assert_async do
        assert expected == Store.get(identifier(event))
      end
    end

    test "when id does not exist returns nil" do
      assert_async do
        assert nil == Store.get("non-existant-id")
      end
    end
  end

  describe "get_all/0" do
    test "returns all DataDefinitionViews" do
      Enum.each(1..3, fn index ->
        Brook.Test.with_event(@instance, fn ->
          event = %Extract{
            id: "extract-#{index}",
            dataset_id: "id-#{index}",
            subset_id: "default",
            source: Source.Fake.new!(),
            destination: Destination.Fake.new!(),
            decoder: Decoder.Json.new!([])
          }

          Store.update_definition(event)
        end)
      end)

      assert_async do
        assert 3 == length(Store.get_all())
      end
    end
  end

  test "does not persist a persist when it is invalid" do
    event = %Load{
      id: "persist-1",
      dataset_id: "p-broken",
      subset_id: "default",
      source: Source.Fake.new!(),
      destination: nil
    }

    Brook.Test.with_event(@instance, fn ->
      Store.update_definition(event)
    end)

    assert_async do
      assert nil == Store.get(identifier(event))
    end
  end

  test "does not persist a transform when it is invalid" do
    event = %Transform{
      id: "transform-1",
      dataset_id: "t-broken",
      subset_id: "default",
      dictionary: nil,
      steps: []
    }

    Brook.Test.with_event(@instance, fn ->
      Store.update_definition(event)
    end)

    assert_async do
      assert nil == Store.get(identifier(event))
    end
  end
end
