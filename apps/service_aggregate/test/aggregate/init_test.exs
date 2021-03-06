defmodule Aggregate.InitTest do
  use ExUnit.Case
  use Placebo

  import Definition, only: [identifier: 1]
  @instance Aggregate.Application.instance()

  setup do
    allow Aggregate.Feed.Supervisor.start_child(any()), return: {:ok, :pid}
    on_exit(fn -> Brook.Test.clear_view_state(@instance, "feeds") end)

    :ok
  end

  test "starts all saved feeds" do
    extract1 =
      Extract.new!(
        id: "extract1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new!(),
        decoder: Decoder.Noop.new(),
        dictioanry: [],
        destination: Destination.Fake.new!()
      )

    extract2 =
      Extract.new!(
        id: "extract2",
        dataset_id: "ds2",
        subset_id: "sb2",
        source: Source.Fake.new!(),
        decoder: Decoder.Noop.new(),
        dictioanry: [],
        destination: Destination.Fake.new!()
      )

    extract3 =
      Extract.new!(
        id: "extract3",
        dataset_id: "ds3",
        subset_id: "sb3",
        source: Source.Fake.new!(),
        decoder: Decoder.Noop.new(),
        dictioanry: [],
        destination: Destination.Fake.new!()
      )

    Brook.Test.with_event(@instance, fn ->
      [extract1, extract2, extract3]
      |> Enum.each(fn extract ->
        identifier(extract)
        |> Aggregate.ViewState.Extractions.persist(extract)
      end)
    end)

    assert {:ok, :state} = Aggregate.Init.on_start(:state)

    assert_called(Aggregate.Feed.Supervisor.start_child(extract1))
    assert_called(Aggregate.Feed.Supervisor.start_child(extract2))
    assert_called(Aggregate.Feed.Supervisor.start_child(extract3))
  end
end
