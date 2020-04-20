defmodule Profile.Event.HandlerTest do
  use ExUnit.Case
  use Placebo

  @instance Profile.Application.instance()

  import Events, only: [extract_start: 0, profile_update: 0]
  import Definition, only: [identifier: 1]
  alias Profile.ViewState

  setup do
    allow Profile.Feed.Supervisor.start_child(any()), return: {:ok, :pid}
    on_exit(fn -> Brook.Test.clear_view_state(@instance, "feeds") end)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new!(),
        decoder: Decoder.Noop.new(),
        destination:
          Kafka.Topic.new!(
            endpoints: [localhost: 9092],
            name: "topic-1"
          ),
        dictionary: []
      )

    [extract: extract, key: identifier(extract)]
  end

  describe "handling #{extract_start()} event" do
    test "starts the feed", %{extract: extract} do
      Brook.Test.send(@instance, extract_start(), "testing", extract)
      assert_called Profile.Feed.Supervisor.start_child(extract)
    end

    test "saves the extraction object", %{extract: extract, key: key} do
      Brook.Test.send(@instance, extract_start(), "testing", extract)
      assert {:ok, extract} == ViewState.Extractions.get(key)
    end
  end

  describe "handling #{profile_update()} event" do
    setup do
      update =
        Profile.Update.new!(
          dataset_id: "ds1",
          subset_id: "sb1",
          stats: %{
            "stat1" => "4"
          }
        )

      [update: update, key: identifier(update)]
    end

    test "saves the profile object", %{update: update, key: key} do
      stats = update.stats

      Brook.Test.send(@instance, profile_update(), "testing", update)

      assert {:ok, ^stats} = ViewState.Stats.get(key)
    end
  end
end
