defmodule Profile.Reducer.TemporalTest do
  use ExUnit.Case

  alias Profile.Reducer.Temporal

  setup do
    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Timestamp.new!(name: "ts", format: "%Y")
      ])

    [dictionary: dictionary]
  end

  test "aggregates a temporal range", %{dictionary: dictionary} do
    events =
      [
        %{"name" => "joe", "ts" => to_ts(2020, 01, 01, 00, 00, 00)},
        %{"name" => "bob", "ts" => to_ts(2021, 12, 12, 12, 12, 12)},
        %{"name" => "john", "ts" => to_ts(2020, 05, 01, 01, 12, 13)}
      ]
      |> Enum.map(&to_elsa_message/1)

    outgoing_events =
      events
      |> Enum.reduce(Temporal.init(dictionary), &Temporal.reduce/2)
      |> Temporal.to_event()
  end

  defp to_elsa_message(value) do
    %Elsa.Message{
      value: value
    }
  end

  defp to_ts(year, month, day, minute, hour, second) do
    NaiveDateTime.new(year, month, day, minute, hour, second)
    |> elem(1)
    |> NaiveDateTime.to_iso8601()
  end
end
