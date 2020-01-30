defmodule AcquireWeb.V2.DataController do
  use AcquireWeb, :controller
  use Properties, otp_app: :service_acquire

  getter(:presto_client, default: Acquire.Db.Presto)

  def select(conn, params) do
    {statement, values} = Acquire.Query.from_params(params)
    {:ok, result} = presto_client().execute(statement, values)

    json(conn, result)
  end
end
