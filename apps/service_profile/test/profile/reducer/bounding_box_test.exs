defmodule Profile.Reducer.BoundingBoxTest do
  use ExUnit.Case
  import Checkov

  setup do
    reducer =
      Profile.Reducer.BoundingBox.new(
        latitude_path: ["lat"],
        longitude_path: ["long"]
      )

    [reducer: reducer]
  end

  describe "init/2" do
    test "will read from stats", %{reducer: reducer} do
      stats = %{
        "bounding_box" => [1.0, 2.0, 3.0, 4.0]
      }

      output = Profile.Reducer.init(reducer, stats)

      assert output.xmin == 1.0
      assert output.ymin == 2.0
      assert output.xmax == 3.0
      assert output.ymax == 4.0
    end
  end

  describe "reduce/2" do
    data_test "reducing (#{long}, #{lat}) into #{inspect(bbox)}", %{reducer: reducer} do
      stats = %{
        "bounding_box" => bbox
      }

      reducer = Profile.Reducer.init(reducer, stats)

      event = %{"long" => long, "lat" => lat}
      output = Profile.Reducer.reduce(reducer, event)

      assert output.xmin == xmin
      assert output.ymin == ymin
      assert output.xmax == xmax
      assert output.ymax == ymax

      where [
        [:bbox, :long, :lat, :xmin, :ymin, :xmax, :ymax],
        [[1.0, 2.0, 3.0, 4.0], 4.0, 1.0, 1.0, 1.0, 4.0, 4.0],
        [[nil, nil, nil, nil], 2.7, 4.7, 2.7, 4.7, 2.7, 4.7]
      ]
    end
  end

  describe "merge/2" do
    data_test "will merge the bounding box from two reducers", %{reducer: reducer} do
      stats1 = %{
        "bounding_box" => bbox1
      }

      reducer1 = Profile.Reducer.init(reducer, stats1)

      stats2 = %{
        "bounding_box" => bbox2
      }

      reducer2 = Profile.Reducer.init(reducer, stats2)

      output = Profile.Reducer.merge(reducer1, reducer2)

      assert output.xmin == xmin
      assert output.ymin == ymin
      assert output.xmax == xmax
      assert output.ymax == ymax

      where [
        [:bbox1, :bbox2, :xmin, :ymin, :xmax, :ymax],
        [[1.0, 2.0, 3.0, 4.0], [2.0, 3.0, 4.0, 5.0], 1.0, 2.0, 4.0, 5.0]
      ]
    end
  end
end
