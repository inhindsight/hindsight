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

  use Properties, otp_app: :service_acquire
  getter(:presto, required: true)

  @behaviour Acquire.Presto

  @impl true
  def execute(statement) do
    presto()
    |> Prestige.new_session()
    |> Prestige.query(statement)
    |> Ok.map(&Prestige.Result.as_maps/1)
  end
end
