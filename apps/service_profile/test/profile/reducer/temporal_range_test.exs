defmodule Profile.Reducer.TemporalRangeTest do
  use ExUnit.Case

  alias Profile.Reducer.TemporalRange

  setup do
    reducer = TemporalRange.new(path: ["ts"])

    [reducer: reducer]
  end

  describe "init/2" do
    test "reads state from map", %{reducer: reducer} do
      stats = %{
        "temporal_range" => %{
          "first" => ~N[2010-01-01 01:01:01] |> NaiveDateTime.to_iso8601(),
          "last" => ~N[2011-01-01 01:01:01] |> NaiveDateTime.to_iso8601()
        }
      }

      output = Profile.Reducer.init(reducer, stats)

      assert output.first == ~N[2010-01-01 01:01:01]
      assert output.last == ~N[2011-01-01 01:01:01]
    end

    test "can handle empty map", %{reducer: reducer} do
      output = Profile.Reducer.init(reducer, %{})

      assert output.first == nil
      assert output.last == nil
    end
  end

  describe "reduce/2" do
    test "can handle comparing to nil", %{reducer: reducer} do
      event = %{"ts" => ~N[2018-04-05 02:03:04] |> NaiveDateTime.to_iso8601()}
      output = Profile.Reducer.reduce(reducer, event)

      assert output.first == ~N[2018-04-05 02:03:04]
      assert output.last == ~N[2018-04-05 02:03:04]
    end

    test "will determine earliest timestamp for first", %{reducer: reducer} do
      stats = %{
        "temporal_range" => %{
          "first" => ~N[2010-01-01 01:01:01] |> NaiveDateTime.to_iso8601(),
          "last" => ~N[2011-01-01 01:01:01] |> NaiveDateTime.to_iso8601()
        }
      }

      event = %{"ts" => ~N[2018-04-05 02:03:04] |> NaiveDateTime.to_iso8601()}

      output = Profile.Reducer.init(reducer, stats) |> Profile.Reducer.reduce(event)

      assert output.first == ~N[2010-01-01 01:01:01]
    end

    test "will determine latest timestamp for last", %{reducer: reducer} do
      stats = %{
        "temporal_range" => %{
          "first" => ~N[2010-01-01 01:01:01] |> NaiveDateTime.to_iso8601(),
          "last" => ~N[2020-01-01 01:01:01] |> NaiveDateTime.to_iso8601()
        }
      }

      event = %{"ts" => ~N[2018-04-05 02:03:04] |> NaiveDateTime.to_iso8601()}

      output = Profile.Reducer.init(reducer, stats) |> Profile.Reducer.reduce(event)

      assert output.last == ~N[2020-01-01 01:01:01]
    end
  end

  describe "merge/2" do
    test "can merge two instances of the reducer", %{reducer: reducer} do
      stats1 = %{
        "temporal_range" => %{
          "first" => ~N[2010-01-01 01:01:01] |> NaiveDateTime.to_iso8601(),
          "last" => ~N[2020-01-01 01:01:01] |> NaiveDateTime.to_iso8601()
        }
      }

      reducer1 = Profile.Reducer.init(reducer, stats1)

      stats2 = %{
        "temporal_range" => %{
          "first" => ~N[2012-01-01 01:01:01] |> NaiveDateTime.to_iso8601(),
          "last" => ~N[2024-01-01 01:01:01] |> NaiveDateTime.to_iso8601()
        }
      }

      reducer2 = Profile.Reducer.init(reducer, stats2)

      output = Profile.Reducer.merge(reducer1, reducer2)
      assert output.first == ~N[2010-01-01 01:01:01]
      assert output.last == ~N[2024-01-01 01:01:01]
    end
  end
end
