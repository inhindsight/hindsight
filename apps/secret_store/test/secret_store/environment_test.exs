defmodule SecretStore.EnvironmentTest do
  use ExUnit.Case
  alias SecretStore.Environment

  describe "get/3" do
    setup do
      on_exit(fn -> System.put_env("SECRET_ENV", "") end)
    end

    test "assembles variable from secret name and key" do
      System.put_env("FOO_BAR", "one")
      assert Environment.get("foo", "bar", nil) == "one"
    end

    test "uses SECRET_ENV as part of variable name when set" do
      System.put_env("FOO_BAR_ABC", "two")
      System.put_env("SECRET_ENV", "abc")
      assert Environment.get("foo", "bar", nil) == "two"
    end

    test "ignores any nil values in variable name" do
      System.put_env("ABC", "three")
      assert Environment.get("Abc", nil, nil) == "three"
    end

    test "returns default if variable not set" do
      assert Environment.get("lmn", "op", "qrs") == "qrs"
    end
  end
end
