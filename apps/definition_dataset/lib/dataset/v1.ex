defmodule Dataset.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Dataset{
      version: version(1),
      id: id(),
      owner_id: id(),
      title: required_string(),
      description: spec(is_binary()),
      keywords: spec(is_list()),
      license: required_string(),
      created_ts: spec(ts?()),
      profile:
        schema(%{
          updated_ts: optional_ts(),
          profiled_ts: optional_ts(),
          modified_ts: optional_ts(),
          spatial: optional_bbox(),
          temporal: optional_range()
        })
    })
  end

  defp optional_ts, do: spec(empty?() or ts?())
  defp optional_bbox, do: spec((is_list() and empty?()) or bbox?())
  defp optional_range, do: spec((is_list() and empty?()) or temporal_range?())
end
