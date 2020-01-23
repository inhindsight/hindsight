defmodule Extract.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Extract{
      version: version(1),
      id: id(),
      dataset_id: id(),
      name: required_string(),
      destination: required_string(),
      steps: spec(is_list() and not_nil?()),
      dictionary: of_struct(Dictionary.Impl)
    })
  end
end
