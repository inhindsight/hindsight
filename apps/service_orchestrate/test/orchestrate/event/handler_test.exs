defmodule Orchestrate.Event.HandlerTest do
  use ExUnit.Case
  use Placebo

  import Events,
    only: [
      schedule_start: 0,
      schedule_end: 0,
      dataset_delete: 0,
      transform_define: 0,
      load_start: 0
    ]

  import Definition, only: [identifier: 1]
  import AssertAsync
  import ExUnit.CaptureLog

  alias Quantum.Job
  alias Orchestrate.ViewState

  @instance Orchestrate.Application.instance()
  @moduletag capture_log: true

  setup do
    allow(UUID.uuid4(), return: "fake_uuid")
    on_exit(fn ->
      Brook.Test.clear_view_state(
        Orchestrate.Application.instance(),
        ViewState.Schedules.collection()
      )

      Orchestrate.Scheduler.delete_all_jobs()
    end)

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
            source: Source.Fake.new!(),
            decoder: Decoder.Noop.new(),
            destination: Destination.Fake.new!(),
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
          Load.new!(
            id: "fake_uuid",
            dataset_id: "ds1",
            subset_id: "kpi",
            source: Source.Fake.new!(),
            destination:
              Presto.Table.new!(
                url: "http://localhost:8080",
                name: "table-1"
              )
          ),
          Load.new!(
            id: "fake_uuid",
            dataset_id: "ds1",
            subset_id: "kpi",
            source: Source.Fake.new!(),
            destination: Channel.Topic.new!(name: "ds1")
          )
        ]
      )

    [schedule: schedule, key: identifier(schedule)]
  end

  describe "handling #{schedule_start()} events" do
    test "establishes job to send events on proper cadence", %{schedule: schedule} do
      expected_cron = Crontab.CronExpression.Parser.parse!(schedule.cron)
      expected_name = :"#{schedule.dataset_id}__#{schedule.subset_id}"
      expected_task = {Orchestrate, :run_extract, [schedule.dataset_id, schedule.subset_id]}

      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      assert_async do
        job = Orchestrate.Scheduler.find_job(expected_name)
        assert job.schedule == expected_cron
        assert job.task == expected_task
      end
    end

    test "schedules compaction on configured cadence", %{schedule: schedule} do
      expected_cron = Crontab.CronExpression.Parser.parse!(schedule.compaction_cron)
      expected_name = :"#{schedule.dataset_id}__#{schedule.subset_id}_compaction"
      expected_task = {Orchestrate, :run_compaction, [schedule.dataset_id, schedule.subset_id]}

      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      assert_async do
        compact = Orchestrate.Scheduler.find_job(expected_name)
        assert compact.schedule == expected_cron
        assert compact.task == expected_task
      end
    end

    test "schedules compaction on default cadence", %{schedule: schedule} do
      schedule = %{schedule | compaction_cron: "@default"}
      expected_name = :"#{schedule.dataset_id}__#{schedule.subset_id}_compaction"

      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      assert %{schedule: actual_cron} = Orchestrate.Scheduler.find_job(expected_name)
      [hour] = actual_cron.hour
      assert [0] == actual_cron.minute
      assert hour >= 0
      assert hour < 24
    end

    test "does not schedule compaction for schedules without Presto.Table loads", %{
      schedule: schedule
    } do
      [_persist, broadcast] = schedule.load
      schedule = %{schedule | load: [broadcast]}
      expected_name = :"#{schedule.dataset_id}__#{schedule.subset_id}_compaction"

      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      assert nil == Orchestrate.Scheduler.find_job(expected_name)
    end

    test "sends #{transform_define()} event", %{schedule: schedule} do
      transform = schedule.transform

      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      assert_receive {:brook_event, %{type: "transform:define", data: ^transform}}
    end

    test "sends #{load_start()} events", %{schedule: schedule} do
      [persist, broadcast] = schedule.load

      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      assert_receive {:brook_event, %{type: load_start(), data: ^persist}}
      assert_receive {:brook_event, %{type: load_start(), data: ^broadcast}}
    end

    test "saves schedule to view state", %{schedule: schedule} do
      Brook.Test.send(@instance, schedule_start(), "testing", schedule)

      assert_async do
        assert {:ok, ^schedule} = ViewState.Schedules.get(identifier(schedule))
      end
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
  end

  describe "handling #{schedule_end()} events" do
    test "deletes job", %{schedule: schedule, key: key} do
      Orchestrate.Scheduler.new_job()
      |> Job.set_name(:"#{schedule.dataset_id}__#{schedule.subset_id}")
      |> Job.set_schedule(Crontab.CronExpression.Parser.parse!("* * * * *"))
      |> Job.set_task({IO, :puts, ["hello"]})
      |> Orchestrate.Scheduler.add_job()

      Brook.Test.with_event(@instance, fn -> ViewState.Schedules.persist(key, schedule) end)
      Brook.Test.send(@instance, schedule_end(), "testing", schedule)

      assert_async do
        assert {:ok, nil} = ViewState.Schedules.get(key)
      end
    end
  end

  describe "handling #{dataset_delete()} events" do
    test "deletes job and state", %{schedule: schedule, key: key} do
      Orchestrate.Scheduler.new_job()
      |> Job.set_name(:"#{schedule.dataset_id}__#{schedule.subset_id}")
      |> Job.set_schedule(Crontab.CronExpression.Parser.parse!("* * * * *"))
      |> Job.set_task({IO, :puts, ["hello"]})
      |> Orchestrate.Scheduler.add_job()

      Brook.Test.with_event(@instance, fn -> ViewState.Schedules.persist(key, schedule) end)

      delete = %Delete{id: "123", dataset_id: schedule.dataset_id, subset_id: schedule.subset_id}

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      assert_async do
        name = "#{schedule.dataset_id}__#{schedule.subset_id}"
        refute Orchestrate.Scheduler.find_job(:"#{name}")
        refute Orchestrate.Scheduler.find_job(:"#{name}_compaction")
      end

      assert_async do
        assert {:ok, nil} == ViewState.Schedules.get(key)
      end
    end
  end
end
