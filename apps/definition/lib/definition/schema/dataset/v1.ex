defmodule Definition.Schema.Dataset.V1 do
  @behaviour Definition.Schema

  import Norm
  import Definition.Schema.Validation

  @impl Definition.Schema
  def s do
    schema(%Definition.Dataset{
      version: spec(fn v -> v == 1 end),
      id: string(),
      owner_id: string(),
      title: string(),
      description: spec(is_binary()),
      keywords: spec(is_list()),
      license: string(),
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
  defp string, do: spec(is_binary() and not_empty?())
  defp optional_bbox, do: spec((is_list() and empty?()) or bbox?())
  defp optional_range, do: spec((is_list() and empty?()) or temporal_range?())
end
