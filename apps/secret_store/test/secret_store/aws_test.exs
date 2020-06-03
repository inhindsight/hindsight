defmodule SecretStore.AwsTest do
  use ExUnit.Case
  use Placebo
  require Temp.Env
  alias SecretStore.Aws

  setup do
    secret = ~s|{"foo":"bar"}|
    allow ExAws.SecretsManager.get_secret_value(any()), exec: fn x -> x end
    allow ExAws.request(any()), return: {:ok, %{"SecretString" => secret}}

    [secret: secret]
  end

  describe "get/3" do
    test "assembles secret id from secret name and key" do
      expect ExAws.SecretsManager.get_secret_value("defined"), return: "defined"
      Aws.get("defined", "keyname")
    end

    test "returns default if secret does not exist" do
      expect ExAws.request("abc"), return: {:error, {:http_error, 400, %{status_code: 400}}}
      assert Aws.get("abc", nil, "xyz") == "xyz"
    end

    test "returns default if key value not set" do
      assert Aws.get("defined", "abc", "123") == "123"
    end

    test "returns raw data string when key isn't specified", %{secret: secret} do
      assert Aws.get("defined", nil, nil) == secret
    end

    test "returns key value when key specified" do
      assert Aws.get("defined", "foo", nil) == "bar"
    end
  end

  describe "get/3 in custom secret environment" do
    Temp.Env.modify([%{app: :secret_store, key: SecretStore, set: [secret_environment: "abc"]}])

    test "uses configured secret_environment value as part of secret id" do
      expect ExAws.SecretsManager.get_secret_value("defined-abc"), return: :ok
      Aws.get("defined", "keyname")
    end
  end
end
