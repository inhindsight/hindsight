defmodule Data.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Data{
      version: version(1),
      dataset_id: id(),
      extract_id: id(),
      payload: schema(%{})
    })
  end
end
