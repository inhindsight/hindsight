defmodule Transform.Wkt.Point do
  @moduledoc """
  `Transform.Step.t()` impl for transformation of latitude/longitude into a
  well-known text (WKT) point object.

  ## Init options

  * `longitude` - String or list of strings as path to `Dictionary.Type.Longitude` field.
  * `latitude` - String or list of strings as path to `Dictionary.Type.Latitude` field.
  * `to` - String or list of strings as path to transformed value field.
  """
  use Definition, schema: Transform.Wkt.Point.V1
  use JsonSerde, alias: "transform_wkt_point"

  @type t :: %__MODULE__{
          longitude: String.t(),
          latitude: String.t(),
          to: String.t()
        }

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
  @moduledoc false
  use Definition.Schema

  def s do
    schema(%Transform.Wkt.Point{
      longitude: access_path(),
      latitude: access_path(),
      to: access_path()
    })
  end
end
