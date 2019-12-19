defmodule DefinitionFaker.Dataset do
  @moduledoc false

  def default do
    %{
      version: 1,
      id: Faker.UUID.v4(),
      owner_id: Faker.UUID.v4(),
      title: title(),
      description: Faker.Lorem.Shakespeare.hamlet(),
      keywords: Faker.Util.list(5, &Faker.Company.buzzword/0),
      license: Faker.Util.pick(["Apache", "GNU", "BDS", "MIT"]),
      created_ts: timestamp(360),
      profile: %{
        updated_ts: timestamp(90),
        profiled_ts: timestamp(120),
        modified_ts: timestamp(180),
        spatial: bbox(),
        temporal: temporal_range()
      }
    }
  end

  defp title do
    [Faker.Color.fancy_name(), Faker.Color.En.name(), random_chars(5)]
    |> Enum.join(" ")
  end

  defp bbox do
    lat = Faker.Address.latitude()
    lon = Faker.Address.longitude()
    [lat, lon, lat + 1, lon + 1]
  end

  defp temporal_range do
    [Faker.DateTime.backward(360), Faker.DateTime.forward(360)]
    |> Enum.map(&DateTime.to_iso8601/1)
  end

  defp random_chars(count) do
    Enum.map_join(1..count, fn _ -> Faker.Util.upper_letter() end)
  end

  defp timestamp(step) do
    Faker.DateTime.backward(step)
    |> DateTime.to_iso8601()
  end
end
