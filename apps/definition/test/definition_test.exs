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

    test "makes schema/0 available to get current version schema" do
      assert Foo.schema() == Foo.V2.s()
    end
  end

  describe "new/1" do
    test "handles input with string keys" do
      input = %{"version" => 2, "bar" => 33}
      assert {:ok, %Foo{version: 2, bar: 33}} = Foo.new(input)
    end

    test "accepts a Keyword list input" do
      assert {:ok, %Foo{bar: 42}} = Foo.new(version: 2, bar: 42)
    end

    test "returns exception for other list input" do
      assert {:error, %Foo.InputError{} = ex} = Foo.new([:foo])
      assert ex.message == [:foo]
    end
  end

  describe "from_json/1" do
    test "turns JSON into new struct" do
      input = ~s/{"version": 2, "bar": 9001}/
      assert {:ok, %Foo{bar: 9001}} = Foo.from_json(input)
    end

    test "returns error tuple for invalid JSON" do
      assert {:error, %Jason.DecodeError{}} = Foo.from_json("{a, b}")
    end

    test "returns exception for invalid new/1 input" do
      input = ~s/[{"version": 2, "bar": 0}]/
      assert {:error, %Foo.InputError{}} = Foo.from_json(input)
    end
  end
end
