defmodule Profile.Event.HandlerTest do
  use ExUnit.Case
  use Placebo

  @instance Profile.Application.instance()

  import Events, only: [extract_start: 0, profile_update: 0]

  setup do
    Brook.Test.clear_view_state(@instance, "feeds")
  end

  describe "#{extract_start()}" do
    setup do
      allow(Profile.Feed.Supervisor.start_child(any()), return: {:ok, :pid})

      extract =
        Extract.new!(
          id: "extract-1",
          dataset_id: "ds1",
          subset_id: "sb1",
          source: Source.Fake.new!(),
          decoder: Decoder.Noop.new(),
          destination: Kafka.Topic.new!(
            endpoints: [localhost: 9092],
            name: "topic-1"
          ),
          dictionary: []
        )

      [extract: extract]
    end

    test "starts the feed", %{extract: extract} do
      Brook.Test.send(@instance, extract_start(), "testing", extract)

      assert_called(Profile.Feed.Supervisor.start_child(extract))
    end

    test "saves the feed", %{extract: extract} do
      Brook.Test.send(@instance, extract_start(), "testing", extract)

      assert {:ok, extract} == Profile.Feed.Store.get_extract("ds1", "sb1")
    end
  end

  describe "#{profile_update()}" do
    setup do
      update =
        Profile.Update.new!(
          dataset_id: "ds1",
          subset_id: "sb1",
          stats: %{
            "stat1" => "4"
          }
        )

      [update: update]
    end

    test "persists stats", %{update: update} do
      Brook.Test.send(@instance, profile_update(), "testing", update)

      assert {:ok, %{"stat1" => "4"}} == Profile.Feed.Store.get_stats("ds1", "sb1")
    end
  end
end
