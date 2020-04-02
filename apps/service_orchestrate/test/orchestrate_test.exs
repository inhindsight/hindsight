defmodule OrchestrateTest do
  use ExUnit.Case
  use Placebo
  import Events, only: [extract_start: 0, compact_start: 0]
  import ExUnit.CaptureLog

  @instance Orchestrate.Application.instance()

  setup do
    Brook.Test.clear_view_state(@instance, "schedules")

    schedule =
      Schedule.new!(
        id: "schedule-1",
        dataset_id: "ds1",
        subset_id: "kpi",
        cron: "* * * * *",
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
            id: "persist-1",
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
            id: "broadcast-1",
            dataset_id: "ds1",
            subset_id: "kpi",
            source: Source.Fake.new!(),
            destination: Channel.Topic.new!(name: "kpi")
          )
        ]
      )

    [schedule: schedule]
  end

  describe "run_extract/1" do
    test "should send extract:start event", %{schedule: schedule} do
      allow UUID.uuid4(), return: "uuid-1"

      Brook.Test.with_event(@instance, fn ->
        Orchestrate.Schedule.Store.persist(schedule)
      end)

      Orchestrate.run_extract(schedule.dataset_id, schedule.subset_id)

      extract = schedule.extract |> Map.put(:id, "uuid-1")

      assert_receive {:brook_event, %{type: extract_start(), data: ^extract}}
    end

    test "should log an error if schedule does not exist", %{schedule: schedule} do
      log =
        capture_log([level: :error], fn ->
          Orchestrate.run_extract(schedule.dataset_id, schedule.subset_id)
        end)

      assert log =~
               "Unable to find schedule with : dataset_id #{schedule.dataset_id} subset_id #{
                 schedule.subset_id
               }"
    end
  end

  describe "run_compaction" do
    test "should send a #{compact_start()} event", %{schedule: schedule} do
      Brook.Test.with_event(@instance, fn ->
        Orchestrate.Schedule.Store.persist(schedule)
      end)

      [persist, _] = schedule.load

      Orchestrate.run_compaction(schedule.dataset_id, schedule.subset_id)

      assert_receive {:brook_event, %Brook.Event{type: compact_start(), data: ^persist}}
    end

    test "should log an error when schedule does not exit" do
      log =
        capture_log([level: :error], fn ->
          Orchestrate.run_compaction("ds1", "sb1")
        end)

      assert log =~ "Unable to find schedule with : dataset_id ds1 subset_id sb1"
    end
  end
end
