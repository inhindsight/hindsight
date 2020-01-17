defmodule Orchestrate.Event.Handler do
  use Brook.Event.Handler
  require Logger

  import Definition.Events, only: [schedule_start: 0, schedule_end: 0]
  alias Quantum.Job

  def handle_event(%Brook.Event{type: schedule_start(), data: %Schedule{} = schedule} = event) do
    case parse_cron(schedule.cron) do
      {:ok, cron} ->
        Orchestrate.Scheduler.new_job()
        |> Job.set_name(:"#{schedule.id}")
        |> Job.set_schedule(cron)
        |> Job.set_task({Orchestrate, :run_schedule, [schedule.id]})
        |> Orchestrate.Scheduler.add_job()

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
end
