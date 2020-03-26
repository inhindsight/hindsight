defmodule Orchestrate.Event.HandlerTest do
  use ExUnit.Case
  import Events, only: [schedule_start: 0, schedule_end: 0, dataset_delete: 0]
  import AssertAsync
  import ExUnit.CaptureLog

  alias Quantum.Job

  @instance Orchestrate.Application.instance()
  @moduletag capture_log: true

  setup do
    Brook.Test.clear_view_state(@instance, "schedules")
    Orchestrate.Scheduler.delete_all_jobs()

    schedule =
      Schedule.new!(
        id: "schedule-1",
        dataset_id: "ds1",
        subset_id: "kpi",
        cron: "* * * * *",
        compaction_cron: "0 10 * * *",
        extract:
          Extract.new!(
            id: "extract-1",
            dataset_id: "ds1",
            subset_id: "kpi",
            destination: Destination.Fake.new!(),
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
            source: Source.Fake.new(),
            destination: "table-1",
            schema: []
          ),
          Load.Broadcast.new!(
            id: "broadcast-1",
            dataset_id: "ds1",
            subset_id: "kpi",
            source: Source.Fake.new(),
            destination: "ds1"
          )
        ]
      )

    [schedule: schedule]
  end

  test "schedules extract job on schedule:start", %{schedule: schedule} do
    Brook.Test.send(@instance, schedule_start(), "testing", schedule)

    expected_cron = Crontab.CronExpression.Parser.parse!(schedule.cron)
    expected_name = :"#{schedule.dataset_id}__#{schedule.subset_id}"
    expected_task = {Orchestrate, :run_extract, [schedule.dataset_id, schedule.subset_id]}

    assert_async do
      assert %{name: ^expected_name, schedule: ^expected_cron, task: ^expected_task} =
               Orchestrate.Scheduler.find_job(expected_name)
    end

    assert_async do
      assert schedule == Orchestrate.Schedule.Store.get!(schedule.dataset_id, schedule.subset_id)
    end
  end

  describe "compaction" do
    test "schedules compaction job on schedule:start", %{schedule: schedule} do
      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      expected_cron = Crontab.CronExpression.Parser.parse!(schedule.compaction_cron)
      expected_name = :"#{schedule.dataset_id}__#{schedule.subset_id}_compaction"
      expected_task = {Orchestrate, :run_compaction, [schedule.dataset_id, schedule.subset_id]}

      assert_async do
        assert %{name: ^expected_name, schedule: ^expected_cron, task: ^expected_task} =
                 Orchestrate.Scheduler.find_job(expected_name)
      end
    end

    test "schedule compaction job according to @default scheule", %{schedule: schedule} do
      schedule = %{schedule | compaction_cron: "@default"}

      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      expected_name = :"#{schedule.dataset_id}__#{schedule.subset_id}_compaction"

      assert %{schedule: actual_cron} = Orchestrate.Scheduler.find_job(expected_name)
      [hour] = actual_cron.hour
      assert [0] == actual_cron.minute
      assert hour >= 0
      assert hour < 24
    end

    test "should not schedule job is no Load.Persist is available", %{schedule: schedule} do
      [_persist, broadcast] = schedule.load
      schedule = %{schedule | load: [broadcast]}

      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      expected_name = :"#{schedule.dataset_id}__#{schedule.subset_id}_compaction"

      assert nil == Orchestrate.Scheduler.find_job(expected_name)
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
    |> Job.set_name(:"#{schedule.dataset_id}__#{schedule.subset_id}")
    |> Job.set_schedule(Crontab.CronExpression.Parser.parse!("* * * * *"))
    |> Job.set_task({IO, :puts, ["hello"]})
    |> Orchestrate.Scheduler.add_job()

    Brook.Test.with_event(@instance, fn ->
      Orchestrate.Schedule.Store.persist(schedule)
    end)

    Brook.Test.send(@instance, schedule_end(), "testing", schedule)

    assert_async do
      stored_schedule = Orchestrate.Schedule.Store.get!(schedule.dataset_id, schedule.subset_id)
      assert Orchestrate.Schedule.Store.done?(stored_schedule)
    end
  end

  test "deletes job and state on definition:delete", %{schedule: schedule} do
    Orchestrate.Scheduler.new_job()
    |> Job.set_name(:"#{schedule.dataset_id}__#{schedule.subset_id}")
    |> Job.set_schedule(Crontab.CronExpression.Parser.parse!("* * * * *"))
    |> Job.set_task({IO, :puts, ["hello"]})
    |> Orchestrate.Scheduler.add_job()

    Brook.Test.with_event(@instance, fn ->
      Orchestrate.Schedule.Store.persist(schedule)
    end)

    delete = %Delete{id: "123", dataset_id: schedule.dataset_id, subset_id: schedule.subset_id}

    Brook.Test.send(@instance, dataset_delete(), "testing", delete)

    assert_async do
      assert nil ==
               Orchestrate.Scheduler.find_job(:"#{schedule.dataset_id}__#{schedule.subset_id}")
    end

    assert_async do
      assert nil ==
               Orchestrate.Scheduler.find_job(
                 :"#{schedule.dataset_id}__#{schedule.subset_id}_compaction"
               )
    end

    assert_async do
      assert nil == Orchestrate.Schedule.Store.get!(schedule.dataset_id, schedule.subset_id)
    end
  end
end
