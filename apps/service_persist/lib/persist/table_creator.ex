defmodule Persist.TableCreator do
  @callback create(table :: String.t(), dictionary :: Dictionary.t()) :: :ok | {:error, term}
end

defmodule Persist.TableCreator.Presto do
  @behaviour Persist.TableCreator
  use Properties, otp_app: :service_persist

  alias Persist.Dictionary.Translator

  getter(:url, required: true)
  getter(:user, required: true)
  getter(:catalog, required: true)
  getter(:schema, required: true)

  @impl Persist.TableCreator
  def create(table, dictionary) do
    columns =
      Enum.map(dictionary, fn type ->
        result = Translator.translate_type(type)
        "#{result.name} #{result.type}"
      end)
      |> Enum.join(",")

    create_table = "CREATE TABLE IF NOT EXISTS #{table} (#{columns}) with ( format = 'AVRO' )"

    case Prestige.execute(new_session(), create_table) do
      {:ok, _} -> :ok
      error_result -> error_result
    end
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
