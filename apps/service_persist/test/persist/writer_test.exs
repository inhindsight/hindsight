defmodule Persist.WriterTest do
  use ExUnit.Case
  require Temp.Env
  import Mox

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Writer,
      set: [
        writer: Writer.PrestoMock,
        url: "http://localhost:8080",
        user: "test_user",
        catalog: "test_catalog",
        schema: "test_schema"
      ]
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  describe "start_link/1" do
    test "will call presto writer" do
      test = self()

      load =
        Load.Persist.new!(
          id: "persist-1",
          dataset_id: "ds1",
          name: "bobby",
          source: "topic-1",
          destination: "table_bobby",
          schema: [
            %Dictionary.Type.String{name: "name"},
            %Dictionary.Type.Integer{name: "age"}
          ]
        )

      Writer.PrestoMock
      |> expect(:start_link, fn arg ->
        send(test, {:start_link, arg})
        {:ok, :pid}
      end)

      assert {:ok, :pid} = Persist.Writer.start_link(load: load)

      assert_receive {:start_link, init_arg}
      assert "http://localhost:8080" == Keyword.get(init_arg, :url)
      assert "test_user" == Keyword.get(init_arg, :user)
      assert "test_catalog" == Keyword.get(init_arg, :catalog)
      assert "test_schema" == Keyword.get(init_arg, :schema)
      assert "table_bobby" == Keyword.get(init_arg, :table)
      assert [{"name", "varchar"}, {"age", "integer"}] == Keyword.get(init_arg, :table_schema)
    end
  end

  describe "writer/2" do
    setup do
      test = self()

      Writer.PrestoMock
      |> expect(:write, fn server, messages, opts ->
        send(test, {:write, server, messages, opts})
        :ok
      end)

      :ok
    end

    test "will send message to presto writer" do
      schema = [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]

      messages = [
        %{"name" => "john", "age" => 21},
        %{"name" => "kelly", "age" => 43}
      ]

      assert :ok = Persist.Writer.write(:pid, messages, schema: schema)

      expected = [
        ["'john'", 21],
        ["'kelly'", 43]
      ]

      assert_receive {:write, :pid, ^expected, _}
    end

    test "will support hierarchichal data" do
      schema = [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"},
        %Dictionary.Type.List{name: "colors", item_type: Dictionary.Type.String},
        %Dictionary.Type.Map{
          name: "spouse",
          fields: [
            %Dictionary.Type.String{name: "name"},
            %Dictionary.Type.Integer{name: "age"},
            %Dictionary.Type.List{name: "colors", item_type: Dictionary.Type.String}
          ]
        },
        %Dictionary.Type.List{
          name: "friends",
          item_type: Dictionary.Type.Map,
          fields: [
            %Dictionary.Type.String{name: "name"},
            %Dictionary.Type.Integer{name: "age"}
          ]
        }
      ]

      messages = [
        %{
          "name" => "george",
          "age" => 21,
          "colors" => ["red", "blue"],
          "spouse" => %{"name" => "shirley", "age" => 23, "colors" => ["yellow", "green"]},
          "friends" => [%{"name" => "joe", "age" => 47}, %{"name" => "frank", "age" => 51}]
        }
      ]

      assert :ok = Persist.Writer.write(:pid, messages, schema: schema)

      expected = [
        [
          "'george'",
          21,
          "array['red','blue']",
          "row('shirley',23,array['yellow','green'])",
          "array[row('joe',47),row('frank',51)]"
        ]
      ]

      assert_receive {:write, :pid, ^expected, _}
    end
  end
end
