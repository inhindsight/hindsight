defmodule Orchestrate do
  import Definition.Events, only: [send_extract_start: 3]
  require Logger

  @instance Orchestrate.Application.instance()
  @author "orchestrate"

  def run_schedule(id) do
    case Orchestrate.Schedule.Store.get(id) do
      {:ok, nil} ->
        Logger.error("#{__MODULE__}: Unable to find schedule with id: #{id}")

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
