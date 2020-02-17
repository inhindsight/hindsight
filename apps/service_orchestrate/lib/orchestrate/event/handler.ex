defmodule Orchestrate.Event.Handler do
  use Brook.Event.Handler
  require Logger

  import Events,
    only: [
      schedule_start: 0,
      schedule_end: 0,
      send_transform_define: 3
    ]

  import Definition, only: [identifier: 1]

  alias Quantum.Job

  @instance Orchestrate.Application.instance()

  def handle_event(%Brook.Event{type: schedule_start(), data: %Schedule{} = schedule} = event) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{schedule_start()}: #{inspect(schedule)}"
    end)

    case parse_cron(schedule.cron) do
      {:ok, cron} ->
        create_extract_job(schedule, cron)
        send_transform_define(@instance, "orchestrate", schedule.transform)
        Enum.each(schedule.load, &send_load_event/1)
        Orchestrate.Schedule.Store.persist(schedule)

      {:error, reason} ->
        Logger.error("Unable to process #{inspect(event)}: reason #{inspect(reason)}")
        :ok
    end
  end

  def handle_event(%Brook.Event{type: schedule_end(), data: %Schedule{} = schedule}) do
    Orchestrate.Scheduler.delete_job(:"#{identifier(schedule)}")
    Orchestrate.Schedule.Store.delete(schedule.dataset_id, schedule.subset_id)
  end

  defp parse_cron(cron) do
    number_of_fields = String.split(cron) |> length()
    Crontab.CronExpression.Parser.parse(cron, number_of_fields == 7)
  end

  defp create_extract_job(schedule, cron) do
    Orchestrate.Scheduler.new_job()
    |> Job.set_name(:"#{identifier(schedule)}")
    |> Job.set_schedule(cron)
    |> Job.set_task({Orchestrate, :run_extract, [schedule.dataset_id, schedule.subset_id]})
    |> Orchestrate.Scheduler.add_job()
  end

  defp send_load_event(load) do
    type = Events.get_event_type("load", "start", load)
    Brook.Event.send(@instance, type, "orchestrate", load)
  end
end
