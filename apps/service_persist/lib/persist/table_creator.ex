defmodule Persist.TableCreator do
  use Properties, otp_app: :service_persist

  @callback create(table :: String.t(), dictionary :: Dictionary.t()) :: :ok | {:error, term}
  @callback create_from(table :: String.t(), from :: String.t()) :: {:ok, term} | {:error, term}

  getter(:impl, default: Persist.TableCreator.Presto)

  def create(table, dictionary) do
    impl().create(table, dictionary)
  end

  def create_from(table, from) do
    impl().create_from(table, from)
  end
end

defmodule Persist.TableCreator.Presto do
  @behaviour Persist.TableCreator
  use Properties, otp_app: :service_persist

  alias Persist.Dictionary.Translator

  getter(:url, required: true)
  getter(:user, required: true)
  getter(:catalog, required: true)
  getter(:schema, required: true)
  getter(:format, default: "JSON")

  @impl Persist.TableCreator
  def create(table, dictionary) do
    columns =
      Enum.map(dictionary, fn type ->
        result = Translator.translate_type(type)
        "#{result.name} #{result.type}"
      end)
      |> Enum.join(",")

    create_table = "CREATE TABLE IF NOT EXISTS #{table} (#{columns}) with ( format = '#{format()}' )"

    case Prestige.execute(new_session(), create_table) do
      {:ok, _} -> :ok
      error_result -> error_result
    end
  end

  @impl Persist.TableCreator
  def create_from(table, from) do
    create_table = "CREATE TABLE #{table} WITH (format = '#{format()}') AS SELECT * FROM #{from}"

    Prestige.execute(new_session(), create_table)
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
