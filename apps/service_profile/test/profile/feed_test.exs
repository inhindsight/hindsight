defmodule Profile.FeedTest do
  use ExUnit.Case

  describe "determine_reducers/1" do
    test "should init a temporal reduder for a timestamp field" do
      dictionary =
        Dictionary.from_list([
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Map.new!(
            name: "map1",
            dictionary: [
              Dictionary.Type.Timestamp.new!(name: "deep-ts", format: "%Y")
            ]
          ),
          Dictionary.Type.Timestamp.new!(name: "ts", format: "%Y")
        ])

      reducers = Profile.Feed.determine_reducers(dictionary, [], [])

      assert reducers == [
               Profile.Reducer.TemporalRange.new(path: ["ts"])
             ]
    end

    test "should init a temporal reducer from a nested timestamp field" do
      dictionary =
        Dictionary.from_list([
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Map.new!(
            name: "record1",
            dictionary: [
              Dictionary.Type.Map.new!(
                name: "record2",
                dictionary: [
                  Dictionary.Type.Timestamp.new!(name: "ts", format: "%Y")
                ]
              )
            ]
          )
        ])

      reducers = Profile.Feed.determine_reducers(dictionary, [], [])

      assert reducers == [
               Profile.Reducer.TemporalRange.new(path: ["record1", "record2", "ts"])
             ]
    end

    test "should add bounding box when latitude and longitude field found" do
      dictionary = Dictionary.from_list([
        Dictionary.Type.Longitude.new!(name: "long"),
        Dictionary.Type.Latitude.new!(name: "lat")
      ])

      reducers = Profile.Feed.determine_reducers(dictionary, [], [])

      assert reducers == [
        Profile.Reducer.BoundingBox.new(longitude_path: ["long"], latitude_path: ["lat"])
      ]
    end
  end
end
