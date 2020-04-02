defmodule Extract.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      source: impl_of(Source),
      decoder: impl_of(Decoder),
      destination: impl_of(Destination),
      dictionary: of_struct(Dictionary.Impl)
    })
  end
end
