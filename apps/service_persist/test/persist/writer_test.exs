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
    test "will send message to presto writer" do
      test = self()

      Writer.PrestoMock
      |> expect(:write, fn server, messages, opts ->
        send(test, {:write, server, messages, opts})
        :ok
      end)

      messages = [
        %{"name" => "john", "age" => 21},
        %{"name" => "kelly", "age" => 43}
      ]

      assert :ok = Persist.Writer.write(:pid, messages)

      expected = [
        %{"name" => "john", "age" => 21},
        %{"name" => "kelly", "age" => 43}
      ]

      assert_receive {:write, :pid, ^expected, _}
    end
  end
end
