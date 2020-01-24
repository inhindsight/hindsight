defmodule Acquire.Presto do
  # TODO
  @moduledoc false

  @type statement :: String.t()
  @type result :: map

  @callback execute(statement) :: {:ok, [result]} | {:error, term}
end

defmodule Acquire.Presto.Client do
  # TODO
  @moduledoc false

  @behaviour Acquire.Presto

  @url "http://localhost:8080"
  @user "acquire"
  @catalog "hive"
  @schema "default"

  @impl true
  def execute(statement) do
    Prestige.new_session(url: @url, user: @user, catalog: @catalog, schema: @schema)
    |> Prestige.query(statement)
    |> Ok.map(&Prestige.Result.as_maps/1)
  end
end
