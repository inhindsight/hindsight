defmodule Profile.Feed.FlowTest do
  use ExUnit.Case
  require Temp.Env

  import Definition, only: [identifier: 1]

  @instance Profile.Application.instance()

  Temp.Env.modify([
    %{
      app: :service_profile,
      key: Profile.Feed.Flow,
      set: [
        window_limit: 2,
        window_unit: :second
      ]
    }
  ])

  setup do
    on_exit(fn -> Brook.Test.clear_view_state(@instance, "feeds") end)
    :ok
  end

  test "aggregates message over a configured period and calls to configured reducers" do
    dataset_id = "ds1"
    subset_id = "sb1"

    reducers = [
      Profile.Reducer.MinMax.new(path: [Access.key(:value), "count"]),
      Profile.Reducer.LongestString.new(path: [Access.key(:value), "name"])
    ]

    assert {:ok, _pid} =
             start_supervised(
               {Profile.Feed.Flow,
                dataset_id: dataset_id,
                subset_id: subset_id,
                from_specs: [Profile.Simple.Producer],
                into_specs: [{Profile.Test.Consumer, pid: self()}],
                reducers: reducers}
             )

    events = [
      to_elsa_message(%{"name" => "joe", "count" => 1}),
      to_elsa_message(%{"name" => "john", "count" => 2})
    ]

    Profile.Simple.Producer.inject_events(events)

    assert_receive {:event, %{"min" => 1, "max" => 2, "longest_string" => 4}}, 3_000

    events = [
      to_elsa_message(%{"name" => "mel", "count" => 4}),
      to_elsa_message(%{"name" => "john", "count" => 7})
    ]

    Profile.Simple.Producer.inject_events(events)

    assert_receive {:event, %{"min" => 1, "max" => 7}}, 3_000

    events = [
      to_elsa_message(%{"name" => "bob", "count" => 5})
    ]

    Profile.Simple.Producer.inject_events(events)

    refute_receive {:event, _}, 3_000
  end

  test "gets it initial state from brook" do
    Brook.Test.with_event(@instance, fn ->
      profile =
        Profile.Update.new!(
          dataset_id: "ds1",
          subset_id: "sb1",
          stats: %{"min" => 23, "max" => 52}
        )

      identifier(profile)
      |> Profile.ViewState.Stats.persist(profile)
    end)

    assert {:ok, _pid} =
             start_supervised(
               {Profile.Feed.Flow,
                dataset_id: "ds1",
                subset_id: "sb1",
                from_specs: [Profile.Simple.Producer],
                into_specs: [{Profile.Test.Consumer, pid: self()}],
                reducers: [
                  Profile.Reducer.MinMax.new(path: [Access.key(:value), "count"])
                ]}
             )

    events = [
      to_elsa_message(%{"name" => "bob", "count" => 5})
    ]

    Profile.Simple.Producer.inject_events(events)

    assert_receive {:event, %{"min" => 5, "max" => 52}}, 3_000
  end

  defp to_elsa_message(value) do
    %Elsa.Message{
      value: value
    }
  end
end
