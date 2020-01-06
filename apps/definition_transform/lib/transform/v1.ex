defmodule Transform.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Transform{
      version: spec(fn v -> v == 1 end),
      id: spec(is_binary() and not_empty?()),
      dataset_id: spec(is_binary() and not_empty?()),
      dictionary: spec(is_list()),
      steps: spec(is_list())
    })
  end
end
