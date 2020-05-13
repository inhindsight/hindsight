defmodule Acquire.Db.Presto do
  @moduledoc false

  use Properties, otp_app: :service_acquire
  getter(:presto, required: true)

  @behaviour Acquire.Db

  @impl true
  def execute(template, values) do
    presto()
    |> Prestige.new_session()
    |> Prestige.query(template, values)
    |> Ok.map(&Prestige.Result.as_maps/1)
  end
end
