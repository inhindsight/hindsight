defmodule ProfileTest do
  use ExUnit.Case
  use Divo
  use Annotated.Retry
  require Temp.Env

  import Events, only: [profile_update: 0, extract_start: 0]

  @instance Profile.Application.instance()

  @moduletag divo: true, integration: true

  Temp.Env.modify([
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
        source: Source.Fake.new!(),
        decoder: Decoder.Noop.new(),
        destination:
          Kafka.Topic.new!(
            endpoints: [localhost: 9092],
            name: "topic-ds1"
          ),
        dictionary: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Timestamp.new!(name: "ts", format: "%Y"),
          Dictionary.Type.Longitude.new!(name: "longy"),
          Dictionary.Type.Latitude.new!(name: "latty")
        ]
      )

    Brook.Test.send(@instance, extract_start(), "testing", extract)

    wait_for_topic("topic-ds1")

    messages =
      [
        %{
          "name" => "joe",
          "ts" => to_iso(~N[2010-01-01 05:06:07]),
          "longy" => 3.5,
          "latty" => 17.8
        },
        %{
          "name" => "bob",
          "ts" => to_iso(~N[2012-01-01 07:08:09]),
          "longy" => 2.1,
          "latty" => 15.0
        },
        %{
          "name" => "sally",
          "ts" => to_iso(~N[2012-02-02 11:10:09]),
          "longy" => 2.3,
          "latty" => 21.2
        }
      ]
      |> Enum.map(&Jason.encode!/1)

    produce("topic-ds1", messages)

    first = to_iso(~N[2010-01-01 05:06:07])
    last = to_iso(~N[2012-02-02 11:10:09])

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
                          },
                          "bounding_box" => [2.1, 15.0, 3.5, 21.2]
                        }
                      }
                    }},
                   20_000

    messages =
      [
        %{
          "name" => "joe",
          "ts" => to_iso(~N[2011-01-01 05:06:07]),
          "longy" => 7.1,
          "latty" => 17.0
        },
        %{
          "name" => "bob",
          "ts" => to_iso(~N[2012-01-01 07:08:09]),
          "longy" => 2.3,
          "latty" => 18.0
        },
        %{
          "name" => "sally",
          "ts" => to_iso(~N[2014-02-02 11:10:09]),
          "longy" => 5.0,
          "latty" => 13.0
        }
      ]
      |> Enum.map(&Jason.encode!/1)

    produce("topic-ds1", messages)

    first = to_iso(~N[2010-01-01 05:06:07])
    last = to_iso(~N[2014-02-02 11:10:09])

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
                          },
                          "bounding_box" => [2.1, 13.0, 7.1, 21.2]
                        }
                      }
                    }},
                   20_000
  end

  @retry with: constant_backoff(1_000) |> take(20)
  defp produce(topic, messages) do
    Elsa.produce([localhost: 9092], topic, messages)
  catch
    _, reason ->
      {:error, reason}
  end

  @retry with: constant_backoff(1_000) |> take(20)
  defp wait_for_topic(topic) do
    case Elsa.topic?([localhost: 9092], topic) do
      true -> {:ok, true}
      false -> {:error, false}
    end
  end

  defp to_iso(date_time), do: NaiveDateTime.to_iso8601(date_time)
end
