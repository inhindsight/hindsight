defmodule Acquire.Presto do
  # TODO
  @moduledoc false

  @type statement :: String.t()
  @type result :: map

  @callback execute(statement, list) :: Ok.result()
end

defmodule Acquire.Presto.Client do
  # TODO
  @moduledoc false

  use Properties, otp_app: :service_acquire
  getter(:presto, required: true)

  @behaviour Acquire.Presto

  @impl true
  def execute(template, values) do
    presto()
    |> Prestige.new_session()
    |> Prestige.query(template, values)
    |> Ok.map(&Prestige.Result.as_maps/1)
  end
end
