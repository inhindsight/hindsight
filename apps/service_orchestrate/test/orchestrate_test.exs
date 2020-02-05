defmodule OrchestrateTest do
  use ExUnit.Case
  use Placebo
  import Events, only: [extract_start: 0]
  import ExUnit.CaptureLog

  @instance Orchestrate.Application.instance()

  describe "run_schedule/1" do
    setup do
      Brook.Test.clear_view_state(@instance, "schedules")

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
              dictionary: [],
              steps: []
            ),
          load: [
            Load.Persist.new!(
              id: "persist-1",
              dataset_id: "ds1",
              name: "kpi",
              source: "topic-1",
              destination: "table-1",
              schema: []
            )
          ]
        )

      [schedule: schedule]
    end

    test "should send extract:start event", %{schedule: schedule} do
      allow UUID.uuid4(), return: "uuid-1"

      Brook.Test.with_event(@instance, fn ->
        Orchestrate.Schedule.Store.persist(schedule)
      end)

      Orchestrate.run_schedule(schedule.id)

      extract = schedule.extract |> Map.put(:id, "uuid-1")

      assert_receive {:brook_event, %{type: extract_start(), data: ^extract}}
    end

    test "should log an error if schedule does not exist", %{schedule: schedule} do
      log =
        capture_log([level: :error], fn ->
          Orchestrate.run_schedule(schedule.id)
        end)

      assert log =~ "Unable to find schedule with id: #{schedule.id}"
    end
  end
end
