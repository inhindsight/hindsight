defmodule Transform.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Transform{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      dictionary: of_struct(Dictionary.Impl),
      steps: spec(is_list() and not_nil?())
    })
  end
end
