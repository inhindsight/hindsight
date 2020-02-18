defmodule Transform.Wkt.Point do
  use Definition, schema: Transform.Wkt.Point.V1

  defstruct [:longitude, :latitude, :to]

  defimpl Transform.Step, for: __MODULE__ do
    import Dictionary.Access, only: [to_access_path: 1]

    def transform_dictionary(%{longitude: longitude, latitude: latitude, to: to}, dictionary) do
      longitude_path = to_access_path(longitude)
      latitude_path = to_access_path(latitude)
      to_path = to_access_path(to)
      new_name = List.wrap(to) |> List.last()

      with :ok <-
             Dictionary.validate_field(dictionary, longitude_path, Dictionary.Type.Longitude),
           :ok <- Dictionary.validate_field(dictionary, latitude_path, Dictionary.Type.Latitude) do
        {:ok, new_field} = Dictionary.Type.Wkt.Point.new(name: new_name)

        put_in(dictionary, to_path, new_field)
        |> Ok.ok()
      end
    end

    def create_function(step, _dictionary) do
      longitude_path = to_access_path(step.longitude)
      latitude_path = to_access_path(step.latitude)
      to_path = to_access_path(step.to)

      fn value ->
        longitude = get_in(value, longitude_path)
        latitude = get_in(value, latitude_path)

        point = %Geo.Point{coordinates: {longitude, latitude}}
        {:ok, wkt} = Geo.WKT.encode(point)

        put_in(value, to_path, wkt)
        |> Ok.ok()
      end
      |> Ok.ok()
    end
  end
end

defmodule Transform.Wkt.Point.V1 do
  use Definition.Schema

  def s do
    schema(%Transform.Wkt.Point{
      longitude: access_path(),
      latitude: access_path(),
      to: access_path()
    })
  end
end
