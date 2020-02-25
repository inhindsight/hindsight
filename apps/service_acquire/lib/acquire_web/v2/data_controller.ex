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

  def query(conn, _) do
    {:ok, query, conn} = Plug.Conn.read_body(conn)

    case presto_client().execute(query, []) do
      {:ok, result} ->
        json(conn, result)

      {:error, response} ->
        conn
        |> put_status(400)
        |> json(response)
    end
  end
end
