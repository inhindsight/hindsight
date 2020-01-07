defmodule Data.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Data{
      version: version(1),
      gather_id: id(),
      load_id: id(),
      payload: schema(%{})
    })
  end
end
