defmodule Orchestrate do
  import Events, only: [send_extract_start: 3]
  require Logger

  @instance Orchestrate.Application.instance()
  @author "orchestrate"

  @spec run_schedule(dataset_id :: String.t(), subset_id :: String.t()) :: no_return
  def run_schedule(dataset_id, subset_id) do
    case Orchestrate.Schedule.Store.get(dataset_id, subset_id) do
      {:ok, nil} ->
        Logger.error(
          "#{__MODULE__}: Unable to find schedule with : dataset_id #{dataset_id} subset_id #{
            subset_id
          }"
        )

      {:ok, schedule} ->
        send_extract(schedule.extract)

      {:error, reason} ->
        Logger.error("#{__MODULE__}: unknown error: #{inspect(reason)}")
    end
  end

  defp send_extract(extract) do
    updated_extract = %{extract | id: UUID.uuid4()}
    send_extract_start(@instance, @author, updated_extract)
  end
end
