defmodule CreateDBTest do
  use ExUnit.Case
  use Placebo

  describe "init/1" do
    setup do
      allow Postgrex.start_link(any()), return: {:ok, :postgrex}
      allow Postgrex.query(:postgrex, any(), []), return: {:ok, :result}

      :ok
    end

    test "creates a DB user for each given service" do
      expect Postgrex.query(:postgrex, "create user foo_user with password 'foo123'", []),
        return: {:ok, :result}

      expect Postgrex.query(:postgrex, "create user bar_user with password 'bar123'", []),
        return: {:ok, :result}

      CreateDB.init(["foo", "bar"])
    end

    test "creates a DB for each given service" do
      expect Postgrex.query(:postgrex, "create database foo_view_state with owner foo_user", []),
        return: {:ok, :result}

      expect Postgrex.query(:postgrex, "create database baz_view_state with owner baz_user", []),
        return: {:ok, :result}

      CreateDB.init(["foo", "baz"])
    end

    test "creates idempotently" do
      allow Postgrex.query(:postgrex, "create user abc_user with password 'abc123'", []),
        return: {:error, %Postgrex.Error{postgres: %{code: :duplicate_object}}}

      allow Postgrex.query(:postgrex, "create user abc_view_state with owner abc_user", []),
        return: {:error, %Postgrex.Error{postgres: %{code: :duplicate_database}}}

      assert CreateDB.init(["abc"]) == :ok
    end

    test "raises an exception in case of failure" do
      allow Postgrex.query(:postgrex, any(), []), return: {:error, %Postgrex.Error{message: :foo}}

      assert_raise Postgrex.Error, fn ->
        CreateDB.init(["foo", "bar", "baz"])
      end
    end
  end
end
