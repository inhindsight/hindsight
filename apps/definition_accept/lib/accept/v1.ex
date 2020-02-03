defmodule Accept.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Accept{
      version: version(1),
      id: id(),
      dataset_id: id(),
      name: required_string(),
      destination: required_string(),
      connection: one_of([of_struct(Accept.Udp), of_struct(Accept.Tcp)])
    })
  end
end
