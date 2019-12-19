defmodule DefinitionTest do
  use ExUnit.Case

  defmodule Foo do
    use Definition, schema: Foo.V2
    defstruct [:version, :bar]

    def migrate(%__MODULE__{version: 1} = old) do
      struct(__MODULE__, %{version: 2, bar: String.to_integer(old.bar)})
    end

    defmodule V1 do
      use Definition.Schema

      def s do
        schema(%Foo{version: spec(fn v -> v == 1 end), bar: spec(is_binary())})
      end
    end

    defmodule V2 do
      use Definition.Schema

      def s do
        schema(%Foo{version: spec(fn v -> v == 2 end), bar: spec(is_integer())})
      end
    end
  end

  describe "__using__/1" do
    test "makes new/1 available to create struct" do
      input = %{version: 2, bar: 9001}
      assert {:ok, %Foo{}} = Foo.new(input)
    end

    test "makes migrate/1 overridable to migrate schema versions" do
      input = %{version: 1, bar: "42"}
      assert {:ok, %Foo{version: 2, bar: 42}} = Foo.new(input)
    end
  end
end
