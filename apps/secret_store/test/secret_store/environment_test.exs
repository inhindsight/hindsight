defmodule SecretStore.EnvironmentTest do
  use ExUnit.Case
  require Temp.Env
  alias SecretStore.Environment

  describe "get/3" do
    test "assembles variable from secret name and key" do
      System.put_env("FOO_BAR", "one")
      assert Environment.get("foo", "bar", nil) == "one"
    end

    test "ignores any nil values in variable name" do
      System.put_env("ABC", "three")
      assert Environment.get("Abc", nil, nil) == "three"
    end

    test "returns default if variable not set" do
      assert Environment.get("lmn", "op", "qrs") == "qrs"
    end
  end

  describe "get/3 in custom secret environment" do
    Temp.Env.modify([%{app: :secret_store, key: SecretStore, set: [secret_environment: "abc"]}])

    test "uses configured secret_environment value as part of variable name when set" do
      System.put_env("FOO_BAR_ABC", "two")
      assert Environment.get("foo", "bar", nil) == "two"
    end
  end
end
