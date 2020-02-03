defmodule Accept.ConnectionTest do
  use ExUnit.Case

  describe "connect/1" do
    test "generates a simple socket child_spec" do
      accept = %Test.Connections.SomeProtocol{port: 6070, key: "4df6cs-alwio"}

      assert [{Test.Connections.SomeProtocol, [port: 6070, key: "4df6cs-alwio"]}] ==
               Accept.Connection.connect(accept)
    end

    test "generates complex child spec list" do
      accept = %Test.Connections.PooledProtocol{port: 6080, pool: 3}

      assert [
               {Test.Connections.PooledProtocol, [port: 6080, name: :pooled_6080]},
               %{id: 0, start: {PooledWorker, :start_link, [listener: :pooled_6080]}},
               %{id: 1, start: {PooledWorker, :start_link, [listener: :pooled_6080]}},
               %{id: 2, start: {PooledWorker, :start_link, [listener: :pooled_6080]}}
             ] == Accept.Connection.connect(accept)
    end
  end
end
