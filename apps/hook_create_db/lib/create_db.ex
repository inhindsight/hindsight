defmodule CreateDB do
  @moduledoc """
  Execute this module via `init/1` in a hook post-installation. The function
  will create users and DBs for each service passed to `init/1`.

  `CreateDB` relies on the [secret_store](../../secret_store/README.md) app
  for access to the master DB credentials and what secrets should be used to create
  each service's DB.
  """
  use Properties, otp_app: :hook_create_db
  require Logger

  getter(:secret_store, required: true)

  @spec init([String.t()]) :: :ok
  def init(services) do
    with {:ok, postgres_conn} <- get_connection() do
      create_services(postgres_conn, services)
    end
  end

  defp get_connection do
    Postgrex.start_link(
      hostname: secret().get("hindsight-db", "host", "localhost"),
      database: secret().get("hindsight-db", "dbname", "metastore"),
      username: secret().get("hindsight-db", "username", "hive"),
      password: secret().get("hindsight-db", "password", "password123")
    )
  end

  defp create_services(conn, services) do
    Enum.map(services, &String.downcase/1)
    |> Enum.each(&create(&1, conn))
  end

  defp create(service, conn) do
    username = secret().get("#{service}-db", "username", "#{service}_user")

    create_user(conn, service, username)
    |> create_database(service, username)
  end

  defp create_user(conn, service, username) do
    password = secret().get("#{service}-db", "password", "#{service}123")

    Postgrex.query(conn, "create user #{username} with password '#{password}'", [])
    |> case do
      {:ok, _} ->
        Logger.info(fn -> "#{__MODULE__}: #{service} service user created" end)
        conn

      {:error, %{postgres: %{code: :duplicate_object}}} ->
        Logger.warn(fn -> "#{__MODULE__}: #{service} service user already exists" end)
        conn

      {:error, reason} ->
        raise reason
    end
  end

  defp create_database(conn, service, username) do
    Postgrex.query(conn, "create database #{service}_view_state with owner #{username}", [])
    |> case do
      {:ok, _} ->
        Logger.info(fn -> "#{__MODULE__}: #{service} service database created" end)
        conn

      {:error, %{postgres: %{code: :duplicate_database}}} ->
        Logger.warn(fn -> "#{__MODULE__}: #{service} service database already exists" end)
        conn

      {:error, reason} ->
        raise reason
    end
  end

  defp secret do
    storage = secret_store() |> String.capitalize()
    Module.concat([SecretStore, storage])
  end
end
