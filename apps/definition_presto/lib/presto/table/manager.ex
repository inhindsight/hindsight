defmodule Presto.Table.Manager do
  @moduledoc """
  It's more performant to write a data file directly to object storage
  than to write through PrestoDB, but writing some formats directly to
  object storage results in poor read performance. JSON, for example.

  In these cases, we write data files directly to object storage and use
  PrestoDB to copy into a new (and properly) formatted table.

  ## Example

  JSON data is written to a file via `Presto.Table.DataFile` behaviour,
  uploaded to a staging table via `Presto.Table.DataStorage` behaviour,
  and staged JSON data is written to a production table in ORC format through
  PrestoDB with this behaviour.
  """
  use Properties, otp_app: :definition_presto

  @formats %{json: "JSON", avro: "AVRO", orc: "ORC"}

  @callback create(
              session :: Prestige.Session.t(),
              table :: String.t(),
              dictionary :: Dictionary.t(),
              Presto.Table.DataFile.format()
            ) ::
              :ok | {:error, term}
  @callback create_from(
              session :: Prestige.Session.t(),
              table :: String.t(),
              from :: String.t(),
              format :: Presto.Table.DataFile.format(),
              with_data :: boolean
            ) ::
              {:ok, term} | {:error, term}
  @callback copy(
              session :: Prestige.Session.t(),
              from_table :: String.t(),
              to_table :: String.t()
            ) :: {:ok, term} | {:error, term}
  @callback delete(session :: Prestige.Session.t(), table :: String.t()) ::
              {:ok, term} | {:error, term}

  getter(:impl, default: Presto.Table.Manager.Impl)

  def create(session, table, dictionary, format \\ :orc) do
    impl().create(session, table, dictionary, @formats[format])
  end

  def create_from(session, table, from, opts) do
    format = Keyword.get(opts, :format, :orc)
    with_data = Keyword.get(opts, :with_data, false)
    impl().create_from(session, table, from, @formats[format], with_data)
  end

  def copy(session, from_table, to_table) do
    impl().copy(session, from_table, to_table)
  end

  def delete(session, table) do
    impl().delete(session, table)
  end
end

defmodule Presto.Table.Manager.Impl do
  @moduledoc false
  @behaviour Presto.Table.Manager

  alias Presto.Table.Dictionary.Translator

  @impl Presto.Table.Manager
  def create(session, table, dictionary, format) do
    columns =
      Enum.map(dictionary, fn type ->
        result = Translator.translate_type(type)
        "#{result.name} #{result.type}"
      end)
      |> Enum.join(",")

    create_table =
      "CREATE TABLE IF NOT EXISTS #{table} (#{columns}) with ( format = '#{format}' )"

    case Prestige.execute(session, create_table) do
      {:ok, _} -> :ok
      error_result -> error_result
    end
  end

  @impl Presto.Table.Manager
  def create_from(session, table, from, format, false) do
    create_table =
      "CREATE TABLE IF NOT EXISTS #{table} WITH (format = '#{format}') AS SELECT * FROM #{from} WITH NO DATA"

    Prestige.execute(session, create_table)
  end

  def create_from(session, table, from, format, true) do
    create_table =
      "CREATE TABLE IF NOT EXISTS #{table} WITH (format = '#{format}') AS SELECT * FROM #{from}"

    Prestige.execute(session, create_table)
  end

  @impl Presto.Table.Manager
  def copy(session, from_table, to_table) do
    Prestige.execute(session, "INSERT INTO #{to_table} SELECT * FROM #{from_table}")
  end

  @impl Presto.Table.Manager
  def delete(session, table) do
    Prestige.execute(session, "DROP TABLE IF EXISTS #{table}")
  end
end
