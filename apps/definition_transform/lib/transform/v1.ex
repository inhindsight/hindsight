defmodule Transform.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Transform{
      version: version(1),
      id: id(),
      dataset_id: id(),
      dictionary: spec(is_list() and not_nil?()),
      steps: spec(is_list() and not_nil?())
    })
  end
end
