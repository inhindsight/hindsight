defmodule Orchestrate.Event.Handler do
  use Brook.Event.Handler
  require Logger

  import Definition.Events,
    only: [
      schedule_start: 0,
      schedule_end: 0,
      send_transform_define: 3
    ]

  alias Quantum.Job

  @instance Orchestrate.Application.instance()

  def handle_event(%Brook.Event{type: schedule_start(), data: %Schedule{} = schedule} = event) do
    case parse_cron(schedule.cron) do
      {:ok, cron} ->
        create_schedule_job(schedule.id, cron)
        send_transform_define(@instance, "orchestrate", schedule.transform)
        Enum.each(schedule.load, &send_load_event/1)
        Orchestrate.Schedule.Store.persist(schedule)

      {:error, reason} ->
        Logger.error("Unable to process #{inspect(event)}: reason #{inspect(reason)}")
        :ok
    end
  end

  def handle_event(%Brook.Event{type: schedule_end(), data: %Schedule{} = schedule}) do
    Orchestrate.Scheduler.delete_job(:"#{schedule.id}")
    Orchestrate.Schedule.Store.delete(schedule.id)
  end

  defp parse_cron(cron) do
    Crontab.CronExpression.Parser.parse(cron)
  end

  defp create_schedule_job(id, cron) do
    Orchestrate.Scheduler.new_job()
    |> Job.set_name(:"#{id}")
    |> Job.set_schedule(cron)
    |> Job.set_task({Orchestrate, :run_schedule, [id]})
    |> Orchestrate.Scheduler.add_job()
  end

  defp send_load_event(load) do
    type = Definition.Events.get_event_type("start", load)
    Brook.Event.send(@instance, type, "orchestrate", load)
  end
end
