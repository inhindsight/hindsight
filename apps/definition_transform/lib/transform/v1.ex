defmodule Transform.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Transform{
      version: version(1),
      id: id(),
      dataset_id: id(),
      dictionary: spec(is_list()),
      steps: spec(is_list())
    })
  end
end
