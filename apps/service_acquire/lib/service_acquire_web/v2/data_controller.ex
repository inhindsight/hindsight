defmodule AcquireWeb.V2.DataController do
  use AcquireWeb, :controller

  @config Application.get_env(:service_acquire, __MODULE__, [])
  @client Keyword.get(@config, :presto_client, Acquire.Presto.Client)

  def select(conn, params) do
    {:ok, result} =
      Acquire.Query.translate(params)
      |> Ok.map(&@client.execute/1)

    json(conn, result)
  end
end
