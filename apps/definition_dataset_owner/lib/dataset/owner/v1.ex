defmodule Dataset.Owner.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Dataset.Owner{
      version: version(1),
      id: id(),
      name: required_string(),
      title: required_string(),
      description: spec(is_binary()),
      url: spec(is_binary()),
      image: spec(is_binary()),
      contact:
        schema(%{
          name: required_string(),
          email: spec(email?())
        })
    })
  end
end
