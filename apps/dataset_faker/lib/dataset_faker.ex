defmodule DatasetFaker do
  @spec dataset(map()) :: Dataset.t()
  def dataset(override) do
    default()
    |> Map.merge(override)
    |> Dataset.new()
  end

  defp default do
    %{
      version: 1,
      id: Faker.UUID.v4(),
      org_id: Faker.UUID.v4(),
      title: title(),
      description: Faker.Lorem.Shakespeare.hamlet(),
      keywords: Faker.Util.list(5, &Faker.Company.buzzword/0),
      license: Faker.Util.pick(["Apache", "GNU", "BDS", "MIT"]),
      created_ts: timestamp(360),
      modified_ts: timestamp(180),
      contact: %{
        name: Faker.Name.name(),
        email: Faker.Internet.email()
      },
      boundaries: %{
        spatial: bbox(),
        temporal: temporal_range()
      },
      data: []
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
