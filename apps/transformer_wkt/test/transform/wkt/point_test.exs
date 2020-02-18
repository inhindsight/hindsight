defmodule Transformer.WKT.PointTest do
  use ExUnit.Case

  test "transform_dictionary will add point field to dictionary" do
    dictionary =
      Dictionary.from_list([
        Dictionary.Type.Longitude.new!(name: "long"),
        Dictionary.Type.Latitude.new!(name: "lat")
      ])

    step =
      Transformer.Wkt.Point.new!(
        longitude: "long",
        latitude: "lat",
        to: "point"
      )

    assert {:ok, result} = Transform.Step.transform_dictionary(step, dictionary)

    expected =
      Dictionary.from_list([
        Dictionary.Type.Longitude.new!(name: "long"),
        Dictionary.Type.Latitude.new!(name: "lat"),
        Dictionary.Type.Wkt.Point.new!(name: "point")
      ])

    assert result == expected
  end

  test "transform dictionary will add point in heirarchical data" do
    dictionary =
      Dictionary.from_list([
        Dictionary.Type.Map.new!(
          name: "point",
          dictionary: [
            Dictionary.Type.Longitude.new!(name: "longitude"),
            Dictionary.Type.Latitude.new!(name: "latitude")
          ]
        ),
        Dictionary.Type.Map.new!(
          name: "wkt",
          dictionary: [
            Dictionary.Type.String.new!(name: "name")
          ]
        )
      ])

    step =
      Transformer.Wkt.Point.new!(
        longitude: ["point", "longitude"],
        latitude: ["point", "latitude"],
        to: ["wkt", "point"]
      )

    assert {:ok, result} = Transform.Step.transform_dictionary(step, dictionary)

    assert get_in(result, ["wkt", "point"]) ==
             Dictionary.Type.Wkt.Point.new!(name: "point")
  end

  test "transform_dictionary will return an error tuple if longitude is not the correct type" do
    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "longitude"),
        Dictionary.Type.Latitude.new!(name: "latitude")
      ])

    step =
      Transformer.Wkt.Point.new!(
        longitude: "longitude",
        latitude: "latitude",
        to: "point"
      )

    assert {:error, :invalid_longitude} = Transform.Step.transform_dictionary(step, dictionary)
  end

  test "transform_dictionary will return an error tuple if latitude is not the correct type" do
    dictionary =
      Dictionary.from_list([
        Dictionary.Type.Longitude.new!(name: "longitude"),
        Dictionary.Type.String.new!(name: "latitude")
      ])

    step =
      Transformer.Wkt.Point.new!(
        longitude: "longitude",
        latitude: "latitude",
        to: "point"
      )

    assert {:error, :invalid_latitude} = Transform.Step.transform_dictionary(step, dictionary)
  end

  test "transform_function returns function to create point" do
    dictionary =
      Dictionary.from_list([
        Dictionary.Type.Longitude.new!(name: "long"),
        Dictionary.Type.Latitude.new!(name: "lat")
      ])

    step =
      Transformer.Wkt.Point.new!(
        longitude: "long",
        latitude: "lat",
        to: "point"
      )

    value = %{
      "long" => 123.3421,
      "lat" => -34.16
    }

    assert {:ok, function} = Transform.Step.create_function(step, dictionary)
    assert {:ok, result} = function.(value)

    assert result == %{
             "long" => 123.3421,
             "lat" => -34.16,
             "point" => "POINT(123.3421 -34.16)"
           }
  end
end
