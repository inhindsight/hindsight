defmodule ProfileTest do
  use ExUnit.Case
  use Divo
  use Annotated.Retry
  require Temp.Env

  import Events, only: [profile_update: 0, extract_start: 0]

  @instance Profile.Application.instance()

  Temp.Env.modify([
    %{
      app: :service_profile,
      key: Profile.Feed.Producer,
      set: [
        endpoints: [localhost: 9092]
      ]
    },
    %{
      app: :service_profile,
      key: Profile.Feed.Flow,
      set: [
        window_limit: 10,
        window_unit: :second
      ]
    }
  ])

  @tag timeout: :infinity
  test "will profile a dataset" do
    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        destination: "topic-ds1",
        steps: [],
        dictionary: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Timestamp.new!(name: "ts", format: "%Y")
        ]
      )

    Brook.Test.send(@instance, extract_start(), "testing", extract)

    wait_for_topic("topic-ds1")

    messages =
      [
        %{"name" => "joe", "ts" => ~N[2010-01-01 05:06:07] |> NaiveDateTime.to_iso8601()},
        %{"name" => "bob", "ts" => ~N[2012-01-01 07:08:09] |> NaiveDateTime.to_iso8601()},
        %{"name" => "sally", "ts" => ~N[2012-02-02 11:10:09] |> NaiveDateTime.to_iso8601()}
      ]
      |> Enum.map(&Jason.encode!/1)

    Elsa.produce([localhost: 9092], "topic-ds1", messages)

    first = ~N[2010-01-01 05:06:07] |> NaiveDateTime.to_iso8601()
    last = ~N[2012-02-02 11:10:09] |> NaiveDateTime.to_iso8601()

    assert_receive {:brook_event,
                    %Brook.Event{
                      type: profile_update(),
                      data: %Profile.Update{
                        dataset_id: "ds1",
                        subset_id: "sb1",
                        stats: %{
                          "temporal_range" => %{
                            "first" => ^first,
                            "last" => ^last
                          }
                        }
                      }
                    }},
                   20_000

    messages =
      [
        %{"name" => "joe", "ts" => ~N[2011-01-01 05:06:07] |> NaiveDateTime.to_iso8601()},
        %{"name" => "bob", "ts" => ~N[2012-01-01 07:08:09] |> NaiveDateTime.to_iso8601()},
        %{"name" => "sally", "ts" => ~N[2014-02-02 11:10:09] |> NaiveDateTime.to_iso8601()}
      ]
      |> Enum.map(&Jason.encode!/1)

    Elsa.produce([localhost: 9092], "topic-ds1", messages)

    first = ~N[2010-01-01 05:06:07] |> NaiveDateTime.to_iso8601()
    last = ~N[2014-02-02 11:10:09] |> NaiveDateTime.to_iso8601()

    assert_receive {:brook_event,
                    %Brook.Event{
                      type: profile_update(),
                      data: %Profile.Update{
                        dataset_id: "ds1",
                        subset_id: "sb1",
                        stats: %{
                          "temporal_range" => %{
                            "first" => ^first,
                            "last" => ^last
                          }
                        }
                      }
                    }},
                   20_000
  end

  @retry with: constant_backoff(500) |> take(100)
  defp wait_for_topic(topic) do
    case Elsa.topic?([localhost: 9092], topic) do
      true -> {:ok, true}
      false -> {:error, false}
    end
  end
end
