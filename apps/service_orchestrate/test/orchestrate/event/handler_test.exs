defmodule Orchestrate.Event.HandlerTest do
  use ExUnit.Case
  import Events, only: [schedule_start: 0, schedule_end: 0]
  import AssertAsync
  import ExUnit.CaptureLog

  alias Quantum.Job

  @instance Orchestrate.Application.instance()
  @moduletag capture_log: true

  setup do
    Orchestrate.Scheduler.delete_all_jobs()

    schedule =
      Schedule.new!(
        id: "schedule-1",
        dataset_id: "ds1",
        cron: "* * * * *",
        extract:
          Extract.new!(
            id: "extract-1",
            dataset_id: "ds1",
            subset_id: "kpi",
            destination: "topic-1",
            steps: [],
            dictionary: []
          ),
        transform:
          Transform.new!(
            id: "transform-1",
            dataset_id: "ds1",
            subset_id: "kp1",
            dictionary: [],
            steps: []
          ),
        load: [
          Load.Persist.new!(
            id: "persist-1",
            dataset_id: "ds1",
            subset_id: "kpi",
            source: "topic-1",
            destination: "table-1",
            schema: []
          )
        ]
      )

    [schedule: schedule]
  end

  test "schedules job on schedule:start", %{schedule: schedule} do
    Brook.Test.send(@instance, schedule_start(), "testing", schedule)

    expected_cron = Crontab.CronExpression.Parser.parse!(schedule.cron)
    expected_name = :"#{schedule.id}"
    expected_task = {Orchestrate, :run_schedule, [schedule.id]}

    assert_async debug: true do
      assert %{name: ^expected_name, schedule: ^expected_cron, task: ^expected_task} =
               Orchestrate.Scheduler.find_job(:"#{schedule.id}")
    end

    assert_async do
      assert schedule == Orchestrate.Schedule.Store.get!(schedule.id)
    end
  end

  test "sends transform:define event on schedule:start", %{schedule: schedule} do
    Brook.Test.send(@instance, schedule_start(), "testing", schedule)

    transform = schedule.transform
    assert_receive {:brook_event, %{type: "transform:define", data: ^transform}}
  end

  test "sends load:persist:start event on schedule:start", %{schedule: schedule} do
    Brook.Test.send(@instance, schedule_start(), "testing", schedule)

    persist = schedule.load |> List.first()
    assert_receive {:brook_event, %{type: "load:persist:start", data: ^persist}}
  end

  test "logs error when unable to process event", %{schedule: schedule} do
    bad_schedule = Map.put(schedule, :cron, "run once a day")

    event = %Brook.Event{
      type: schedule_start(),
      author: "testing",
      data: bad_schedule,
      create_ts: DateTime.utc_now()
    }

    {:error, expected_reason} = Crontab.CronExpression.Parser.parse("run once a day")

    log =
      capture_log(fn ->
        Orchestrate.Event.Handler.handle_event(event)
      end)

    assert log =~ "Unable to process #{inspect(event)}: reason #{inspect(expected_reason)}"
  end

  test "deletes job on schedule:end", %{schedule: schedule} do
    Orchestrate.Scheduler.new_job()
    |> Job.set_name(:"#{schedule.id}")
    |> Job.set_schedule(Crontab.CronExpression.Parser.parse!("* * * * *"))
    |> Job.set_task({IO, :puts, ["hello"]})
    |> Orchestrate.Scheduler.add_job()

    Brook.Test.with_event(@instance, fn ->
      Orchestrate.Schedule.Store.persist(schedule)
    end)

    Brook.Test.send(@instance, schedule_end(), "testing", schedule)

    assert_async do
      assert nil == Orchestrate.Scheduler.find_job(:"#{schedule.id}")
    end

    assert_async do
      assert nil == Orchestrate.Schedule.Store.get!(schedule.id)
    end
  end
end
