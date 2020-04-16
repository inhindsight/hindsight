defmodule Orchestrate.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  require Logger

  import Events,
    only: [
      schedule_start: 0,
      schedule_end: 0,
      dataset_delete: 0,
      send_transform_define: 3,
      send_load_start: 3
    ]

  import Definition, only: [identifier: 1]

  alias Quantum.Job

  @instance Orchestrate.Application.instance()

  def handle_event(%Brook.Event{type: schedule_start(), data: %Schedule{} = schedule} = event) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{schedule_start()}: #{inspect(schedule)}"
    end)

    with :ok <- create_extract_job(schedule),
         :ok <- create_compaction_job(schedule),
         :ok <- send_transform_define(@instance, "orchestrate", schedule.transform),
         :ok <- Enum.each(schedule.load, &send_load_event/1) do
      Orchestrate.Schedule.Store.persist(schedule)
    else
      {:error, reason} ->
        Logger.error("Unable to process #{inspect(event)}: reason #{inspect(reason)}")
        :ok
    end
  end

  def handle_event(%Brook.Event{type: schedule_end(), data: %Schedule{} = schedule}) do
    Orchestrate.Scheduler.delete_job(:"#{identifier(schedule)}")
    Orchestrate.Schedule.Store.mark_done(schedule)
  end

  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    Orchestrate.Scheduler.delete_job(:"#{identifier(delete)}")
    Orchestrate.Scheduler.delete_job(:"#{identifier(delete)}_compaction")
    Orchestrate.Schedule.Store.delete(delete.dataset_id, delete.subset_id)
  end

  defp parse_cron(cron) do
    number_of_fields = String.split(cron) |> length()
    Crontab.CronExpression.Parser.parse(cron, number_of_fields == 7)
  end

  defp parse_compaction_cron("@default") do
    hour = :rand.uniform(24) - 1
    parse_cron("0 #{hour} * * *")
  end

  defp parse_compaction_cron(cron), do: parse_cron(cron)

  defp create_extract_job(schedule) do
    with {:ok, cron} <- parse_cron(schedule.cron) do
      Orchestrate.Scheduler.new_job()
      |> Job.set_name(:"#{identifier(schedule)}")
      |> Job.set_schedule(cron)
      |> Job.set_task({Orchestrate, :run_extract, [schedule.dataset_id, schedule.subset_id]})
      |> Orchestrate.Scheduler.add_job()
    end
  end

  defp create_compaction_job(schedule) do
    Ok.each(schedule.load, &create_compaction_job(schedule, &1))
  end

  defp create_compaction_job(schedule, %Load{destination: %Presto.Table{}}) do
    with {:ok, cron} <- parse_compaction_cron(schedule.compaction_cron) do
      Orchestrate.Scheduler.new_job()
      |> Job.set_name(:"#{identifier(schedule)}_compaction")
      |> Job.set_schedule(cron)
      |> Job.set_task({Orchestrate, :run_compaction, [schedule.dataset_id, schedule.subset_id]})
      |> Orchestrate.Scheduler.add_job()
    end
  end

  defp create_compaction_job(_schedule, _unknown_struct) do
    :ok
  end

  defp send_load_event(load) do
    send_load_start(@instance, "orchestrate", load)
  end
end
