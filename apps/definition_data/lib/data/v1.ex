defmodule Data.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Data{
      version: spec(fn v -> v == 1 end),
      gather_id: spec(is_binary() and not_empty?()),
      load_id: spec(is_binary() and not_empty?()),
      payload: spec(is_binary())
    })
  end
end
