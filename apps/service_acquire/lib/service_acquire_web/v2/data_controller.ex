defmodule AcquireWeb.V2.DataController do
  use AcquireWeb, :controller
  use Properties, otp_app: :service_acquire

  getter(:presto_client, default: Acquire.Presto.Client)

  def select(conn, params) do
    {:ok, result} =
      Acquire.Query.from_params(params)
      |> Ok.map(fn s -> presto_client().execute(s) end)

    json(conn, result)
  end
end
