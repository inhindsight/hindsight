defmodule Extract.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Extract{
      version: spec(fn v -> v == 1 end),
      id: spec(is_binary() and not_empty?()),
      dataset_id: spec(is_binary() and not_empty?()),
      steps: spec(is_list())
    })
  end
end
