defmodule AcquireWeb.V2.DataController do
  use AcquireWeb, :controller
  use Properties, otp_app: :service_acquire

  getter(:presto_client, default: Acquire.Db.Presto)

  def select(conn, params) do
    {:ok, query} = Acquire.Query.from_params(params)

    statement = Acquire.Queryable.parse_statement(query)
    input = Acquire.Queryable.parse_input(query)

    {:ok, result} = presto_client().execute(statement, input)

    json(conn, result)
  end
end
