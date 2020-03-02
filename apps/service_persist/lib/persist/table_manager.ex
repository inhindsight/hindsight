defmodule Persist.TableManager do
  use Properties, otp_app: :service_persist

  @formats %{json: "JSON", avro: "AVRO", orc: "ORC"}

  @callback create(table :: String.t(), dictionary :: Dictionary.t(), Persist.DataFile.format()) ::
              :ok | {:error, term}
  @callback create_from(table :: String.t(), from :: String.t(), Persist.DataFile.format()) ::
              {:ok, term} | {:error, term}
  @callback copy(from_table :: String.t(), to_table :: String.t()) :: {:ok, term} | {:error, term}

  getter(:impl, default: Persist.TableManager.Presto)

  def create(table, dictionary, format \\ :orc) do
    impl().create(table, dictionary, @formats[format])
  end

  def create_from(table, from, format \\ :orc) do
    impl().create_from(table, from, @formats[format])
  end

  def copy(from_table, to_table) do
    impl().copy(from_table, to_table)
  end
end

defmodule Persist.TableManager.Presto do
  @behaviour Persist.TableManager
  use Properties, otp_app: :service_persist

  alias Persist.Dictionary.Translator

  getter(:url, required: true)
  getter(:user, required: true)
  getter(:catalog, required: true)
  getter(:schema, required: true)

  @impl Persist.TableManager
  def create(table, dictionary, format) do
    columns =
      Enum.map(dictionary, fn type ->
        result = Translator.translate_type(type)
        "#{result.name} #{result.type}"
      end)
      |> Enum.join(",")

    create_table =
      "CREATE TABLE IF NOT EXISTS #{table} (#{columns}) with ( format = '#{format}' )"

    case Prestige.execute(new_session(), create_table) do
      {:ok, _} -> :ok
      error_result -> error_result
    end
  end

  @impl Persist.TableManager
  def create_from(table, from, format) do
    create_table = "CREATE TABLE #{table} WITH (format = '#{format}') AS SELECT * FROM #{from}"

    Prestige.execute(new_session(), create_table)
  end

  @impl Persist.TableManager
  def copy(from_table, to_table) do
    Prestige.execute(new_session(), "INSERT INTO #{to_table} SELECT * FROM #{from_table}")
  end

  defp new_session() do
    Prestige.new_session(
      url: url(),
      user: user(),
      catalog: catalog(),
      schema: schema()
    )
  end
end
