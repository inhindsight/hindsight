defmodule Extract.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      destination: impl_of(Destination),
      steps: spec(is_list() and not_nil?()),
      dictionary: of_struct(Dictionary.Impl),
      message_key: spec(is_list()),
      config: spec(is_map())
    })
  end
end
