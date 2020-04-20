defmodule Orchestrate do
  @moduledoc """
  Functions to send cadenced events (extract, load, compact, etc.).
  """
  import Events, only: [send_extract_start: 3, send_compact_start: 3]
  require Logger

  @instance Orchestrate.Application.instance()
  @author "orchestrate"

  @spec run_extract(dataset_id :: String.t(), subset_id :: String.t()) :: no_return
  def run_extract(dataset_id, subset_id) do
    case Orchestrate.Schedule.Store.get(dataset_id, subset_id) do
      {:ok, nil} ->
        log_no_schedule_error(dataset_id, subset_id)

      {:ok, schedule} ->
        send_extract(schedule.extract)

      {:error, reason} ->
        Logger.error("#{__MODULE__}: unknown error: #{inspect(reason)}")
    end
  end

  @spec run_compaction(dataset_id :: String.t(), subset_id :: String.t()) :: no_return
  def run_compaction(dataset_id, subset_id) do
    case Orchestrate.Schedule.Store.get(dataset_id, subset_id) do
      {:ok, nil} ->
        log_no_schedule_error(dataset_id, subset_id)

      {:ok, schedule} ->
        send_compact_start(@instance, @author, get_load_persist(schedule))

      {:error, reason} ->
        Logger.error("#{__MODULE__}: unknown error: #{inspect(reason)}")
    end
  end

  defp send_extract(extract) do
    updated_extract = %{extract | id: UUID.uuid4()}
    send_extract_start(@instance, @author, updated_extract)
  end

  defp get_load_persist(schedule) do
    Enum.find(schedule.load, fn
      %Load{destination: %Presto.Table{}} -> true
      _ -> false
    end)
  end

  defp log_no_schedule_error(dataset_id, subset_id) do
    Logger.error(
      "#{__MODULE__}: Unable to find schedule with : dataset_id #{dataset_id} subset_id #{
        subset_id
      }"
    )
  end
end
