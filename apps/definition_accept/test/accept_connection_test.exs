defmodule Accept.ConnectionTest do
  use ExUnit.Case

  describe "connect/1" do
    test "generates a simple socket config" do
      accept = %Test.Connections.SomeProtocol{port: 6070, key: "4df6cs-alwio"}

      assert [port: 6070, key: "4df6cs-alwio"] == Accept.Connection.connect(accept)
    end

    test "generates a different config" do
      accept = %Test.Connections.PooledProtocol{port: 6080, pool: 3}

      assert [port: 6080, pool: 3] == Accept.Connection.connect(accept)
    end
  end
end
