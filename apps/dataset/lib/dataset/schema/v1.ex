defmodule Dataset.Schema.V1 do
  @behaviour Dataset.Schema

  import Norm
  import Dataset.Schema.Validation

  @impl Dataset.Schema
  def s do
    schema(%Dataset{
      version: spec(fn v -> v == 1 end),
      id: string(),
      org_id: string(),
      title: string(),
      description: spec(is_binary()),
      keywords: spec(is_list()),
      license: string(),
      created_ts: timestamp(),
      modified_ts: timestamp(),
      contact: contact(),
      boundaries: boundaries(),
      data: spec(is_list())
    })
  end

  defp timestamp, do: spec(is_binary() and ts?())
  defp string, do: spec(is_binary() and not_empty?())
  defp contact, do: schema(%{name: string(), email: spec(email?())})
  defp geo_spatial, do: spec(is_list() and bbox?())
  defp temporal, do: spec(is_list() and ts?() and temporal_range?())

  defp boundaries do
    schema(%{
      spatial: geo_spatial(),
      temporal: temporal()
    })
  end
end
